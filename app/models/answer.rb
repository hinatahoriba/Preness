class Answer < ApplicationRecord
  CHOICES = %w[A B C D].freeze

  belongs_to :attempt
  belongs_to :question

  validates :selected_choice, inclusion: { in: CHOICES }, unless: :skipped
  validates :selected_choice, absence: true, if: :skipped
end
