class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable

  has_many :attempts, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :completed_purchases, -> { completed }, class_name: "Purchase"
  has_many :purchased_mocks, through: :completed_purchases, source: :mock

  validates :terms_agreed, acceptance: { accept: true }, on: :create

  def purchased?(mock)
    purchases.completed.exists?(mock: mock)
  end
end

