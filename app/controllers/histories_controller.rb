class HistoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @completed_attempts = current_user.attempts
      .where.not(completed_at: nil)
      .where(mockable_type: "Mock")
      .includes(:mockable, :mock_analysis_report)
      .order(completed_at: :desc)
  end
end
