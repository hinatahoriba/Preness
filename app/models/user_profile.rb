class UserProfile < ApplicationRecord
  belongs_to :user

  validates :full_name, presence: true
  validates :full_name_kana, presence: true, format: { with: /\A[ぁ-ん\s　]+\z/, message: "はひらがなで入力してください" }
  validates :nickname, presence: true
  validates :age, presence: true, numericality: { only_integer: true, greater_than: 0, less_than: 121 }
  validates :affiliation, presence: true
  validates :study_abroad_plan, inclusion: { in: [true, false] }
  validates :data_usage_agreed, inclusion: { in: [true, false] }
end
