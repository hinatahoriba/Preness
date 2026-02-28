class Part < ApplicationRecord
  PART_TYPES = %w[part_a part_b part_c passages].freeze

  belongs_to :section
  has_many :question_sets, -> { order(:display_order) }, dependent: :destroy

  validates :part_type, presence: true, inclusion: { in: PART_TYPES }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end

