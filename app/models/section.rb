class Section < ApplicationRecord
  SECTION_TYPES = %w[listening structure reading].freeze

  belongs_to :sectionable, polymorphic: true
  has_many :parts, -> { order(:display_order) }, dependent: :destroy

  validates :section_type, presence: true, inclusion: { in: SECTION_TYPES }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end

