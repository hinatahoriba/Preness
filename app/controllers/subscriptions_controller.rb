class SubscriptionsController < ApplicationController
  DEFAULT_TRIAL_DAYS = 7

  before_action :authenticate_user!
  before_action :ensure_stripe_configured!, only: :create_premium

  def create_trial
    subscription = current_user.subscription || current_user.build_subscription

    if subscription.plan_premium? && subscription.status_active?
      redirect_to dashboard_path, alert: "すでにプレミアムプランをご利用中です。"
      return
    end

    if subscription.stripe_subscription_id.present?
      redirect_to dashboard_path, alert: "すでに有料プランの申し込み履歴があります。"
      return
    end

    if subscription.trial_started_at.present?
      redirect_to dashboard_path, alert: "トライアルは1回のみご利用いただけます。"
      return
    end

    now = Time.current
    trial_ends_at = now + trial_days.days

    subscription.assign_attributes(
      plan: :trial,
      status: :active,
      trial_started_at: now,
      trial_ends_at: trial_ends_at,
      current_period_start: now,
      current_period_end: trial_ends_at,
      cancel_at_period_end: false,
      canceled_at: nil,
      ends_at: nil
    )
    subscription.save!

    redirect_to dashboard_path, notice: "#{trial_days}日間のトライアルを開始しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to dashboard_path, alert: "トライアル開始に失敗しました: #{e.record.errors.full_messages.to_sentence}"
  end

  def create_premium
    subscription = current_user.subscription

    if subscription&.plan_premium? && subscription.status_active?
      redirect_to dashboard_path, alert: "すでにプレミアムプランをご利用中です。"
      return
    end

    if subscription&.stripe_subscription_id.present? && (subscription.status_active? || subscription.status_past_due?)
      redirect_to dashboard_path, alert: "すでに有効なサブスクリプションがあります。"
      return
    end

    checkout_session_params = {
      mode: "subscription",
      line_items: [ { price: Rails.configuration.x.stripe.subscription_price_id, quantity: 1 } ],
      metadata: {
        user_id: current_user.id,
        requested_plan: "premium"
      },
      subscription_data: {
        metadata: {
          user_id: current_user.id,
          requested_plan: "premium"
        }
      },
      success_url: subscription_success_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: subscription_cancel_url
    }

    if subscription&.stripe_customer_id.present?
      checkout_session_params[:customer] = subscription.stripe_customer_id
    else
      checkout_session_params[:customer_email] = current_user.email
    end

    session = Stripe::Checkout::Session.create(checkout_session_params)
    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    redirect_to dashboard_path, alert: "プレミアム申し込みの開始に失敗しました: #{e.message}"
  end

  def success
    redirect_to dashboard_path, notice: "プレミアムプランの申し込みを受け付けました。反映まで数秒お待ちください。"
  end

  def cancel
    redirect_to dashboard_path, alert: "プレミアム申し込みをキャンセルしました。"
  end

  private

  def ensure_stripe_configured!
    if Rails.configuration.x.stripe.secret_key.blank?
      redirect_to dashboard_path, alert: "STRIPE_SECRET_KEY が未設定です。"
      return
    end

    return if Rails.configuration.x.stripe.subscription_price_id.present?

    redirect_to dashboard_path, alert: "STRIPE_SUBSCRIPTION_PRICE_ID が未設定です。"
  end

  def trial_days
    configured_days = Rails.configuration.x.stripe.subscription_trial_days.to_i
    configured_days.positive? ? configured_days : DEFAULT_TRIAL_DAYS
  end
end
