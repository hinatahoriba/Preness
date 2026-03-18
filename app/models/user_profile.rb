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
end

