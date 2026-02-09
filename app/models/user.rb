class User < ApplicationRecord
  has_many :user_exams, dependent: :destroy
  has_many :exams, through: :user_exams

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def purchased_exam?(exam)
    user_exams.status_paid.exists?(exam: exam)
  end
end
