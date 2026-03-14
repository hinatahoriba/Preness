class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable

  has_many :attempts, dependent: :destroy
  has_one :user_profile, dependent: :destroy

  validates :terms_agreed, acceptance: { accept: true }, on: :create
end
