module Webhooks
  class StripeController < ActionController::API
    def create
      event = build_event
      return head :bad_request if event.nil?

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "checkout.session.async_payment_failed", "checkout.session.expired"
        handle_checkout_failed(event.data.object)
      when "customer.subscription.created", "customer.subscription.updated"
        handle_subscription_upsert(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_failed"
        handle_invoice_payment_failed(event.data.object)
      end

      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.warn("[StripeWebhook] Invalid payload: #{e.message}")
      head :bad_request
    rescue StandardError => e
      Rails.logger.error("[StripeWebhook] Unexpected error: #{e.class}: #{e.message}")
      head :internal_server_error
    end

    private

    def build_event
      webhook_secret = Rails.configuration.x.stripe.webhook_secret

      if webhook_secret.blank?
        Rails.logger.error("[StripeWebhook] STRIPE_WEBHOOK_SECRET is missing")
        return nil
      end

      Stripe::Webhook.construct_event(
        request.raw_post,
        request.headers["Stripe-Signature"],
        webhook_secret
      )
    end

    def handle_checkout_completed(checkout_session)
      if checkout_session.mode == "subscription"
        handle_subscription_checkout_completed(checkout_session)
      else
        handle_exam_checkout_completed(checkout_session)
      end
    end

    def handle_exam_checkout_completed(checkout_session)
      user_exam = find_user_exam(checkout_session)
      return unless user_exam

      user_exam.with_lock do
        user_exam.update!(
          status: :paid,
          paid_at: user_exam.paid_at || Time.current,
          stripe_checkout_session_id: checkout_session.id,
          stripe_payment_intent_id: checkout_session.payment_intent
        )
      end
    end

    def handle_checkout_failed(checkout_session)
      if checkout_session.mode == "subscription"
        handle_subscription_checkout_failed(checkout_session)
      else
        handle_exam_checkout_failed(checkout_session)
      end
    end

    def handle_exam_checkout_failed(checkout_session)
      user_exam = find_user_exam(checkout_session)
      return unless user_exam
      return if user_exam.status_paid?

      user_exam.update!(
        status: :failed,
        stripe_checkout_session_id: checkout_session.id,
        stripe_payment_intent_id: checkout_session.payment_intent
      )
    end

    def handle_subscription_checkout_completed(checkout_session)
      user = find_user_from_checkout_session(checkout_session)
      return unless user

      stripe_subscription = fetch_stripe_subscription(checkout_session.subscription)
      subscription = user.subscription || user.build_subscription

      assign_subscription_attributes(
        subscription: subscription,
        stripe_customer_id: checkout_session.customer,
        stripe_subscription: stripe_subscription,
        fallback_plan: checkout_session.metadata&.[]("requested_plan"),
        fallback_subscription_id: checkout_session.subscription
      )

      subscription.save! if subscription.new_record? || subscription.changed?
    end

    def handle_subscription_checkout_failed(checkout_session)
      user = find_user_from_checkout_session(checkout_session)
      return unless user

      subscription = user.subscription
      return unless subscription
      return if subscription.plan_trial? && subscription.status_active?
      return if subscription.status_canceled?

      subscription.update!(status: :past_due)
    end

    def handle_subscription_upsert(stripe_subscription)
      user = find_user_from_subscription(stripe_subscription)
      return unless user

      subscription = user.subscription || user.build_subscription
      assign_subscription_attributes(
        subscription: subscription,
        stripe_customer_id: stripe_subscription.customer,
        stripe_subscription: stripe_subscription
      )
      subscription.save! if subscription.new_record? || subscription.changed?
    end

    def handle_subscription_deleted(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      subscription.update!(
        status: :canceled,
        canceled_at: epoch_to_time(stripe_subscription.canceled_at) || Time.current,
        ends_at: epoch_to_time(stripe_subscription.ended_at) || epoch_to_time(stripe_subscription.current_period_end) || Time.current,
        cancel_at_period_end: true
      )
    end

    def handle_invoice_payment_failed(invoice)
      subscription = Subscription.find_by(stripe_customer_id: invoice.customer)
      return unless subscription

      subscription.update!(status: :past_due)
    end

    def assign_subscription_attributes(subscription:, stripe_customer_id:, stripe_subscription:, fallback_plan: nil, fallback_subscription_id: nil)
      subscription.assign_attributes(
        stripe_customer_id: stripe_customer_id || subscription.stripe_customer_id,
        stripe_subscription_id: stripe_subscription&.id || fallback_subscription_id || subscription.stripe_subscription_id,
        stripe_price_id: stripe_subscription&.items&.data&.first&.price&.id || subscription.stripe_price_id,
        plan: resolve_plan(stripe_subscription, fallback_plan),
        status: resolve_status(stripe_subscription&.status),
        trial_started_at: epoch_to_time(stripe_subscription&.trial_start) || subscription.trial_started_at,
        trial_ends_at: epoch_to_time(stripe_subscription&.trial_end) || subscription.trial_ends_at,
        current_period_start: epoch_to_time(stripe_subscription&.current_period_start) || subscription.current_period_start,
        current_period_end: epoch_to_time(stripe_subscription&.current_period_end) || subscription.current_period_end,
        cancel_at_period_end: stripe_subscription&.cancel_at_period_end || false,
        canceled_at: epoch_to_time(stripe_subscription&.canceled_at),
        ends_at: epoch_to_time(stripe_subscription&.ended_at)
      )
    end

    def resolve_plan(stripe_subscription, fallback_plan)
      return :trial if stripe_subscription&.status == "trialing"

      return :trial if fallback_plan == "trial"

      :premium
    end

    def resolve_status(stripe_status)
      case stripe_status
      when "trialing", "active", nil
        :active
      when "past_due", "unpaid", "incomplete"
        :past_due
      when "canceled", "incomplete_expired", "paused"
        :canceled
      else
        :active
      end
    end

    def fetch_stripe_subscription(subscription_id)
      return nil if subscription_id.blank?

      Stripe::Subscription.retrieve(subscription_id)
    rescue Stripe::StripeError => e
      Rails.logger.warn("[StripeWebhook] Failed to retrieve subscription #{subscription_id}: #{e.message}")
      nil
    end

    def find_user_from_checkout_session(checkout_session)
      user_id = checkout_session.metadata&.[]("user_id")
      return User.find_by(id: user_id) if user_id.present?

      subscription = Subscription.find_by(stripe_customer_id: checkout_session.customer)
      subscription&.user
    end

    def find_user_from_subscription(stripe_subscription)
      user_id = stripe_subscription.metadata&.[]("user_id")
      return User.find_by(id: user_id) if user_id.present?

      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id) ||
        Subscription.find_by(stripe_customer_id: stripe_subscription.customer)
      subscription&.user
    end

    def epoch_to_time(epoch_seconds)
      return nil if epoch_seconds.blank?

      Time.zone.at(epoch_seconds)
    end

    def find_user_exam(checkout_session)
      user_exam_id = checkout_session.metadata&.[]("user_exam_id")
      return UserExam.find_by(id: user_exam_id) if user_exam_id.present?

      UserExam.find_by(stripe_checkout_session_id: checkout_session.id)
    end
  end
end
