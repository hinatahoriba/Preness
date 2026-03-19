class Question < ApplicationRecord
  CHOICES = %w[A B C D].freeze
  TAGS = %w[
    shortConv longConv talk
    sentenceStruct verbForm modifierConnect nounPronoun
    vocab inference fact
  ].freeze

  belongs_to :question_set

  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :question_text, presence: true
  validates :choice_a, presence: true
  validates :choice_b, presence: true
  validates :choice_c, presence: true
  validates :choice_d, presence: true
  validates :correct_choice, presence: true, inclusion: { in: CHOICES }
  validates :tag, inclusion: { in: TAGS }, allow_nil: true
end

