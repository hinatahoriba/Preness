class StripeWebhooksController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError
      return render json: { error: "Invalid payload" }, status: :bad_request
    rescue Stripe::SignatureVerificationError
      return render json: { error: "Invalid signature" }, status: :bad_request
    end

    case event.type
    when "checkout.session.completed"
      session = event.data.object
      if session.mode == "subscription"
        Subscriptions::FulfillCheckout.call(session)
      else
        Purchases::FulfillCheckout.call(session)
      end
    end

    render json: { received: true }
  end
end
