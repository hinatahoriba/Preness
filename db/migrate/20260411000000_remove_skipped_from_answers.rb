class RemoveSkippedFromAnswers < ActiveRecord::Migration[8.0]
  def change
    remove_column :answers, :skipped, :boolean, default: false, null: false
  end
end
