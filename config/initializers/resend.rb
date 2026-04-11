require "resend_delivery_method"

ActionMailer::Base.add_delivery_method(
  :resend_api,
  ResendDeliveryMethod,
  api_key: ENV["RESEND_API_KEY"]
)
