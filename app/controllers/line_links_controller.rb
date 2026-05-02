class LineLinksController < ApplicationController
  before_action :store_line_token_and_authenticate

  def show
    token = params[:token].to_s
    link_session = LineLinkSession.pending_valid.find_by(link_token: token)

    if link_session.nil?
      @error = "このリンクは無効または期限切れです. LINEから再度友だち追加してください."
      render :error, status: :unprocessable_entity and return
    end

    if link_session.user_id.present? && link_session.user_id != current_user.id
      @error = "このリンクはすでに別のアカウントで使用されています."
      render :error, status: :unprocessable_entity and return
    end

    nonce = SecureRandom.uuid
    link_session.update!(nonce: nonce, user_id: current_user.id)

    redirect_to "https://access.line.me/dialog/bot/accountLink?linkToken=#{token}&nonce=#{nonce}", allow_other_host: true
  end

  private

  def store_line_token_and_authenticate
    if !user_signed_in? && params[:token].present?
      session[:pending_line_link_token] = params[:token]
    end
    authenticate_user!
  end
end

