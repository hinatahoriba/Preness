module Subscriptions
  class CreateCheckoutSession
    def self.call(user:)
      Stripe::Checkout::Session.create(
        mode: "subscription",
        customer_email: user.email,
        line_items: [{
          price: ENV["STRIPE_PREMIUM_PRICE_ID"],
          quantity: 1
        }],
        metadata: {
          user_id: user.id
        },
        client_reference_id: user.id.to_s,
        success_url: Rails.application.routes.url_helpers.success_subscriptions_url(
          host: ENV.fetch("APP_HOST", "localhost:3000"),
          session_id: "{CHECKOUT_SESSION_ID}"
        ),
        cancel_url: Rails.application.routes.url_helpers.cancel_subscriptions_url(
          host: ENV.fetch("APP_HOST", "localhost:3000")
        )
      )
    end
  end
end
