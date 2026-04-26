class QuestionSet < ApplicationRecord
  belongs_to :part
  has_many :questions, -> { order(:display_order) }, dependent: :destroy

  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :passage, presence: true, if: -> { part&.part_type == "passages" }
  validates :passage_theme, presence: true, if: -> { part&.part_type == "passages" }
end

