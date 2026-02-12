class AuthController < ApplicationController
  def confirmation_pending
    @pending_email = params[:email].presence || session[:pending_confirmation_email]
  end
end
