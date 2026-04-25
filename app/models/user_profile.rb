class UserProfile < ApplicationRecord
  belongs_to :user

  # =====================
  # 定数
  # =====================
  KATAKANA_REGEX = /\A[ァ-ヶー\s　]+\z/.freeze

  ITP_SCORE_RANGE   = 310..677
  TOEIC_SCORE_RANGE = 10..990
  TOEFL_RANGE       = 0..120
  IELTS_RANGE       = 0.0..9.0

  EIKEN_GRADES = %w[1 p1 2 p2 3].freeze

  # =====================
  # 基本プロフィール
  # =====================
  with_options presence: true do
    validates :last_name
    validates :first_name
    validates :nickname
    validates :date_of_birth
    validates :affiliation
  end

  with_options presence: true, format: { with: KATAKANA_REGEX, message: "はカタカナで入力してください" } do
    validates :last_name_kana
    validates :first_name_kana
  end

  # =====================
  # 留学予定
  # =====================
  validates :study_abroad_plan, inclusion: { in: [true, false] }

  # =====================
  # スコア系
  # =====================
  validates :itp_current_score,
            numericality: { only_integer: true,
                            greater_than_or_equal_to: ITP_SCORE_RANGE.begin,
                            less_than_or_equal_to: ITP_SCORE_RANGE.end },
            allow_nil: true

  validates :itp_target_score,
            presence: true,
            numericality: { only_integer: true,
                            greater_than_or_equal_to: ITP_SCORE_RANGE.begin,
                            less_than_or_equal_to: ITP_SCORE_RANGE.end }

  validates :toeic_score,
            numericality: { only_integer: true,
                            greater_than_or_equal_to: TOEIC_SCORE_RANGE.begin,
                            less_than_or_equal_to: TOEIC_SCORE_RANGE.end },
            allow_nil: true

  validates :toefl_ibt_score,
            numericality: { only_integer: true,
                            greater_than_or_equal_to: TOEFL_RANGE.begin,
                            less_than_or_equal_to: TOEFL_RANGE.end },
            allow_nil: true

  validates :ielts_score,
            numericality: { greater_than_or_equal_to: IELTS_RANGE.begin,
                            less_than_or_equal_to: IELTS_RANGE.end },
            allow_nil: true

  validates :eiken_grade, inclusion: { in: EIKEN_GRADES }, allow_nil: true

  # =====================
  # 名前系
  # =====================
  def full_name
    [last_name, first_name].compact.join(" ").strip
  end

  def full_name=(value)
    last, first = value.to_s.strip.split(/\s+/, 2)
    self.last_name  = last
    self.first_name = first if first.present?
  end

  def full_name_kana
    [last_name_kana, first_name_kana].compact.join(" ").strip
  end

  def full_name_kana=(value)
    last, first = value.to_s.strip.split(/\s+/, 2)
    self.last_name_kana  = last
    self.first_name_kana = first if first.present?
  end

  # =====================
  # 年齢
  # =====================
  def age
    return if date_of_birth.blank?

    today = Date.current
    age = today.year - date_of_birth.year

    birthday_passed =
      today.month > date_of_birth.month ||
      (today.month == date_of_birth.month && today.day >= date_of_birth.day)

    birthday_passed ? age : age - 1
  end
end
