module Purchases
  class FulfillCheckout
    def self.call(session)
      purchase = Purchase.find_by(stripe_checkout_session_id: session.id)
      return if purchase.nil?
      return if purchase.completed?

      purchase.update!(
        status: :completed,
        stripe_payment_intent_id: session.payment_intent,
        amount_cents: session.amount_total || 0
      )
    end
  end
end
