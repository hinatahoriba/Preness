class UserProfilesController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!

  def edit
    @user_profile = current_user.user_profile
  end

  def update
    @user_profile = current_user.user_profile
    if @user_profile.update(user_profile_params)
      redirect_to account_setting_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_profile_params
    params.require(:user_profile).permit(
      :last_name, :first_name, :last_name_kana, :first_name_kana,
      :nickname, :date_of_birth, :affiliation, :study_abroad_plan,
      :eiken_grade, :toeic_score, :toefl_ibt_score, :ielts_score,
      :data_usage_agreed
    )
  end
end
