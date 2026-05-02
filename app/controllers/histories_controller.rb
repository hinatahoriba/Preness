class HistoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @completed_attempts = current_user.attempts
      .where.not(completed_at: nil)
      .where(mockable_type: %w[Mock Diagnostic])
      .includes(:mockable, :analysis_report)
      .order(completed_at: :desc)
  end
end
