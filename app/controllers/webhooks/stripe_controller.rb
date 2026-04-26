class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :configure_permitted_parameters

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.error("Stripe Webhook Error: #{e.message}")
      head :bad_request
      return
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "charge.refunded"
      handle_refund(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    purchase = Purchase.find_by(stripe_checkout_session_id: session.id)
    return if purchase.nil? || purchase.completed?

    purchase.update!(
      status: "completed",
      stripe_payment_intent_id: session.payment_intent,
      amount_cents: session.amount_total,
      currency: session.currency,
      purchased_at: Time.current
    )
  end

  def handle_refund(charge)
    purchase = Purchase.find_by(stripe_payment_intent_id: charge.payment_intent)
    return if purchase.nil?

    purchase.update!(status: "refunded")
  end
end
