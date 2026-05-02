class Line::AuthController < ApplicationController
  before_action :authenticate_user!

  LINE_AUTHORIZE_URL = "https://access.line.me/oauth2/v2.1/authorize"
  LINE_TOKEN_URL = "https://api.line.me/oauth2/v2.1/token"
  LINE_PROFILE_URL = "https://api.line.me/v2/profile"

  def connect
    state = SecureRandom.hex(16)
    session[:line_oauth_state] = state

    query = {
      response_type: "code",
      client_id: ENV.fetch("LINE_LOGIN_CLIENT_ID"),
      redirect_uri: line_callback_url,
      state: state,
      scope: "profile",
    }.to_query

    redirect_to "#{LINE_AUTHORIZE_URL}?#{query}", allow_other_host: true
  end

  def callback
    if params[:state] != session.delete(:line_oauth_state)
      return redirect_to account_setting_path, alert: "LINE連携に失敗しました(不正なリクエスト)."
    end

    if params[:error].present?
      return redirect_to account_setting_path, alert: "LINE連携をキャンセルしました."
    end

    token_data = exchange_code(params[:code])
    unless token_data
      return redirect_to account_setting_path, alert: "LINE連携に失敗しました(トークン取得エラー)."
    end

    profile = fetch_profile(token_data["access_token"])
    unless profile
      return redirect_to account_setting_path, alert: "LINEプロフィールの取得に失敗しました."
    end

    line_user_id = profile["userId"]

    if User.where.not(id: current_user.id).exists?(line_user_id: line_user_id)
      return redirect_to account_setting_path, alert: "このLINEアカウントはすでに別のPrenessアカウントと連携済みです."
    end

    current_user.update!(line_user_id: line_user_id)
    redirect_to account_setting_path, notice: "LINEとの連携が完了しました."
  end

  def disconnect
    current_user.update!(line_user_id: nil)
    redirect_to account_setting_path, notice: "LINE連携を解除しました."
  end

  private

  def line_callback_url
    "#{ENV.fetch('LINE_LINK_BASE_URL')}/line/callback"
  end

  def exchange_code(code)
    resp = Faraday.post(LINE_TOKEN_URL) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = {
        grant_type: "authorization_code",
        code: code,
        redirect_uri: line_callback_url,
        client_id: ENV.fetch("LINE_LOGIN_CLIENT_ID"),
        client_secret: ENV.fetch("LINE_LOGIN_CLIENT_SECRET"),
      }.to_query
    end
    resp.success? ? JSON.parse(resp.body) : nil
  rescue StandardError
    nil
  end

  def fetch_profile(access_token)
    resp = Faraday.get(LINE_PROFILE_URL) do |req|
      req.headers["Authorization"] = "Bearer #{access_token}"
    end
    resp.success? ? JSON.parse(resp.body) : nil
  rescue StandardError
    nil
  end
end

