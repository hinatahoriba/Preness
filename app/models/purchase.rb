class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :mock

  validates :stripe_checkout_session_id, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending completed refunded] }
  validates :user_id, uniqueness: { scope: :mock_id, message: "この模擬試験は既に購入済みです" }

  scope :completed, -> { where(status: "completed") }

  def completed?
    status == "completed"
  end
end
