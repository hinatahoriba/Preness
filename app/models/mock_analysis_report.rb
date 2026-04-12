class MockAnalysisReport < ApplicationRecord
  belongs_to :attempt

  STATUSES = %w[pending completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  def pending?   = status == "pending"
  def completed? = status == "completed"
  def failed?    = status == "failed"
end
