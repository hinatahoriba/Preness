Rails.configuration.x.stripe = ActiveSupport::InheritableOptions.new(
  publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"],
  secret_key: ENV["STRIPE_SECRET_KEY"],
  webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"],
  exam_price_id: ENV["STRIPE_EXAM_PRICE_ID"],
  subscription_price_id: ENV["STRIPE_SUBSCRIPTION_PRICE_ID"],
  subscription_trial_days: ENV.fetch("SUBSCRIPTION_TRIAL_DAYS", "7").to_i
)

Stripe.api_key = Rails.configuration.x.stripe.secret_key
