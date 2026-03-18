class UserProfile < ApplicationRecord
  belongs_to :user

  # 基本プロフィール
  validates :last_name, presence: true
  validates :first_name, presence: true
  validates :last_name_kana, presence: true, format: { with: /\A[ァ-ヶー\s　]+\z/, message: "はカタカナで入力してください" }
  validates :first_name_kana, presence: true, format: { with: /\A[ァ-ヶー\s　]+\z/, message: "はカタカナで入力してください" }
  validates :nickname, presence: true
  validates :date_of_birth, presence: true
  validates :affiliation, presence: true

  # 留学予定
  validates :study_abroad_plan, inclusion: { in: [true, false] }

  # TOEFL ITP スコア
  validates :itp_current_score, numericality: { only_integer: true, in: 310..677 }, allow_nil: true
  validates :itp_target_score, presence: true, numericality: { only_integer: true, in: 310..677 }

  # 外部英語検定
  validates :eiken_grade, inclusion: { in: %w[1 p1 2 p2 3] }, allow_nil: true
  validates :toeic_score, numericality: { only_integer: true, in: 10..990 }, allow_nil: true
  validates :toefl_ibt_score, numericality: { only_integer: true, in: 0..120 }, allow_nil: true
  validates :ielts_score, numericality: { in: 0..9.0 }, allow_nil: true

  def full_name
    [last_name, first_name].compact.join(" ").strip
  end

  def full_name=(value)
    parts = value.to_s.strip.split(/\s+/, 2)
    self.last_name = parts[0]
    self.first_name = parts[1]
  end

  def full_name_kana
    [last_name_kana, first_name_kana].compact.join(" ").strip
  end

  def full_name_kana=(value)
    parts = value.to_s.strip.split(/\s+/, 2)
    self.last_name_kana = parts[0]
    self.first_name_kana = parts[1]
  end

  def age
    return if date_of_birth.blank?

    today = Time.zone.today
    years = today.year - date_of_birth.year
    years -= 1 if today < date_of_birth.change(year: today.year)
    years
  end
end
