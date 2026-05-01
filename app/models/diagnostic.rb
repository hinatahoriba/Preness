class Diagnostic < ApplicationRecord
  has_many :sections, as: :sectionable, dependent: :destroy
  has_many :attempts, as: :mockable, dependent: :destroy
end
