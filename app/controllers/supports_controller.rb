class SupportsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def create
    name    = params[:name].to_s.strip
    email   = params[:email].to_s.strip
    subject = params[:subject].to_s.strip
    body    = params[:body].to_s.strip

    if name.blank? || email.blank? || body.blank?
      flash[:alert] = "お名前・メールアドレス・お問い合わせ内容は必須です。"
      return redirect_to support_path
    end

    ContactMailer.notify_admin(name: name, email: email, subject: subject, body: body).deliver_later
    ContactMailer.confirm_to_user(name: name, email: email, subject: subject, body: body).deliver_later

    flash[:notice] = "お問い合わせを送信しました。自動返信メールをご確認ください。"
    redirect_to support_path
  end
end
