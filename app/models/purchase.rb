class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :mock

  enum :status, { pending: "pending", completed: "completed", failed: "failed" }

  validates :amount_cents, presence: true
  validates :user_id, uniqueness: { scope: :mock_id }

  scope :completed, -> { where(status: :completed) }
end
