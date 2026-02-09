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
      user_exam = find_user_exam(checkout_session)
      return unless user_exam
      return if user_exam.status_paid?

      user_exam.update!(
        status: :failed,
        stripe_checkout_session_id: checkout_session.id,
        stripe_payment_intent_id: checkout_session.payment_intent
      )
    end

    def find_user_exam(checkout_session)
      user_exam_id = checkout_session.metadata["user_exam_id"]
      return UserExam.find_by(id: user_exam_id) if user_exam_id.present?

      UserExam.find_by(stripe_checkout_session_id: checkout_session.id)
    end
  end
end
