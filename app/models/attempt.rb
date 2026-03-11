class Attempt < ApplicationRecord
  belongs_to :user
  belongs_to :mockable, polymorphic: true
  has_many :answers, dependent: :destroy

  validates :user_id, uniqueness: { scope: %i[mockable_type mockable_id] }, if: :mock?

  private

  def mock?
    mockable_type == "Mock"
  end
end

