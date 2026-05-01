class Attempt < ApplicationRecord
  belongs_to :user
  belongs_to :mockable, polymorphic: true
  has_many :answers, dependent: :destroy
  has_one :analysis_report, dependent: :destroy

  validates :user_id, uniqueness: { scope: %i[mockable_type mockable_id] }, if: :unique_attempt?

  private

  def unique_attempt?
    mockable_type.in?(%w[Mock Diagnostic])
  end
end

