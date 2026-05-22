class Diagnostic < ApplicationRecord
  has_many :sections, as: :sectionable, dependent: :destroy
  has_many :attempts, as: :mockable, dependent: :destroy

  validate :only_one_record

  private

  def only_one_record
    if Diagnostic.where.not(id: id).exists?
      errors.add(:base, "実力診断は1件のみ登録できます")
    end
  end
end
