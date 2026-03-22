class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :mock

  validates :amount_cents, presence: true
  validates :user_id, uniqueness: { scope: :mock_id }
end
