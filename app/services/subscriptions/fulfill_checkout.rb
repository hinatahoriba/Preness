module Subscriptions
  class FulfillCheckout
    def self.call(session)
      user_id = session.metadata[:user_id]
      user = User.find(user_id)
      
      subscription = user.subscription || user.build_subscription
      subscription.update!(
        stripe_customer_id: session.customer,
        stripe_subscription_id: session.subscription,
        status: "active",
        current_period_start: Time.at(session.created), # 本来はsubscriptionオブジェクトから取得が望ましいが簡易化
        current_period_end: Time.at(session.created + 30.days.to_i) # Webhookの別イベントで更新するのが理想
      )
    end
  end
end
