class InitialSettingsController < ApplicationController
  before_action :authenticate_user!

  def new
    redirect_to mypage_path if current_user.user_profile.present?
    @user_profile = UserProfile.new
  end

  def create
    @user_profile = current_user.build_user_profile(user_profile_params)
    @user_profile.eiken_grade = nil if @user_profile.eiken_grade.blank?
    if @user_profile.save
      redirect_to mypage_path, notice: "初期設定が完了しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_profile_params
    params.require(:user_profile).permit(
      :last_name, :first_name, :last_name_kana, :first_name_kana,
      :nickname, :date_of_birth, :affiliation,
      :study_abroad_plan,
      :itp_current_score, :itp_target_score,
      :eiken_grade, :toeic_score, :toefl_ibt_score, :ielts_score
    )
  end
end
