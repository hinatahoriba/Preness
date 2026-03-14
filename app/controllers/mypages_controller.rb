class MypagesController < ApplicationController
  before_action :authenticate_user!

  def show
    redirect_to new_initial_setting_path unless current_user.user_profile.present?
  end
end
