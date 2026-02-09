class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @paid_user_exams = current_user.user_exams.status_paid.includes(:exam).order(paid_at: :desc)
  end
end
