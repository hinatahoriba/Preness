class MypagesController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!

  def show
    redirect_to new_initial_setting_path and return unless current_user.user_profile.present?
    @diagnostic = Diagnostic.first
  end
end
