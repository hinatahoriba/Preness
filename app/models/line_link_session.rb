class LineLinkSession < ApplicationRecord
  belongs_to :user, optional: true

  scope :pending_valid, -> { where(status: "pending").where("expires_at > ?", Time.current) }

  validates :line_user_id, presence: true
  validates :link_token, presence: true, uniqueness: true
end

