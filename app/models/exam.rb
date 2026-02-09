class Exam < ApplicationRecord
  has_many :user_exams, dependent: :restrict_with_error
  has_many :users, through: :user_exams

  validates :title, presence: true
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def purchased_by?(user)
    return false unless user

    user_exams.paid.exists?(user: user)
  end
end
