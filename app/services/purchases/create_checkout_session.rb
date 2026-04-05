module Purchases
  class CreateCheckoutSession
    def self.call(user:, mock:)
      session = Stripe::Checkout::Session.create(
        mode: "payment",
        customer_email: user.email,
        line_items: [{
          price: ENV["STRIPE_EXAM_PRICE_ID"],
          quantity: 1
        }],
        metadata: {
          user_id: user.id,
          mock_id: mock.id
        },
        client_reference_id: user.id.to_s,
        success_url: Rails.application.routes.url_helpers.success_purchases_url(
          host: ENV.fetch("APP_HOST", "localhost:3000"),
          session_id: "{CHECKOUT_SESSION_ID}"
        ),
        cancel_url: Rails.application.routes.url_helpers.cancel_purchases_url(
          host: ENV.fetch("APP_HOST", "localhost:3000")
        )
      )

      purchase = Purchase.find_or_initialize_by(user: user, mock: mock)
      purchase.update!(
        stripe_checkout_session_id: session.id,
        amount_cents: session.amount_total || 0,
        currency: "jpy",
        status: :pending
      )

      session
    end
  end
end
