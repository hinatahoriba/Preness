class InitialSettingsController < ApplicationController
  before_action :authenticate_user!

  def new
    redirect_to mypage_path if current_user.user_profile.present?
    @user_profile = UserProfile.new(data_usage_agreed: true)
  end

  def create
    @user_profile = current_user.build_user_profile(user_profile_params)
    if @user_profile.save
      redirect_to mypage_path, notice: "初期設定が完了しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_profile_params
    params.require(:user_profile).permit(
      :full_name, :full_name_kana, :nickname, :age,
      :affiliation, :study_abroad_plan, :data_usage_agreed
    )
  end
end
