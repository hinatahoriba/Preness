class Subscription < ApplicationRecord
  belongs_to :user

  enum :plan, {
    trial: "trial",
    premium: "premium"
  }, prefix: true

  enum :status, {
    active: "active",
    past_due: "past_due",
    canceled: "canceled"
  }, prefix: true

  validates :plan, presence: true
  validates :status, presence: true
  validates :user_id, uniqueness: true
  validates :trial_ends_at, presence: true, if: :plan_trial?

  scope :accessible, -> { where(status: [ "active", "past_due" ]) }
end
