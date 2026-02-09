class UserExam < ApplicationRecord
  belongs_to :user
  belongs_to :exam

  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed"
  }, prefix: true

  validates :user_id, uniqueness: { scope: :exam_id }
  validates :status, presence: true
end
