class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @subscription = current_user.subscription
    @trial_days = Rails.configuration.x.stripe.subscription_trial_days.to_i
    @paid_user_exams = current_user.user_exams.status_paid.includes(:exam).order(paid_at: :desc)
  end
end
