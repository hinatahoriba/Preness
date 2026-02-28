class Attempt < ApplicationRecord
  belongs_to :user
  belongs_to :mockable, polymorphic: true
  has_many :answers, dependent: :destroy
end

