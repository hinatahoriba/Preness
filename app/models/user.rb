class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable

  validates :username, presence: true
  validates :terms_agreed, acceptance: { accept: true }, on: :create
end
