class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable

  has_many :attempts, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  has_one :subscription, dependent: :destroy

  validates :terms_agreed, acceptance: { accept: true }, on: :create

  def premium?
    subscription&.active?
  end

  def today_exercise_count
    # JST(日本標準時)での当日0:00〜23:59までの回数をカウント
    attempts.where(
      mockable_type: "Exercise",
      created_at: Time.current.in_time_zone('Tokyo').beginning_of_day..Time.current.in_time_zone('Tokyo').end_of_day
    ).count
  end

  def can_start_exercise?
    premium? || today_exercise_count < 3
  end
end
