class Subscription < ApplicationRecord
  belongs_to :user

  enum :status, {
    inactive: "inactive",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    incomplete: "incomplete",
    incomplete_expired: "incomplete_expired",
    unpaid: "unpaid"
  }, default: :inactive

  def active?
    status == "active"
  end
end
