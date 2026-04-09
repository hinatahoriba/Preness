class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "no-reply@preness-app.com")
  layout "mailer"
end
