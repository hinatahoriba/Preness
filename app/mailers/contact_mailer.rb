class ContactMailer < ApplicationMailer
  ADMIN_EMAIL = "support@preness.jp".freeze

  # 管理者宛通知
  def notify_admin(name:, email:, subject:, body:)
    @name    = name
    @email   = email
    @subject = subject
    @body    = body

    mail(
      to: ADMIN_EMAIL,
      reply_to: email,
      subject: "[お問い合わせ] #{subject}"
    )
  end

  # ユーザー宛自動返信
  def confirm_to_user(name:, email:, subject:, body:)
    @name    = name
    @subject = subject
    @body    = body

    mail(
      to: email,
      subject: "【Preness】お問い合わせを受け付けました"
    )
  end
end
