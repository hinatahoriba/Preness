class Mock < ApplicationRecord
  has_many :sections, -> { order(:display_order) }, as: :sectionable, dependent: :destroy
  has_many :attempts, as: :mockable, dependent: :destroy
  has_many :purchases, dependent: :destroy

  validates :title, presence: true
end

