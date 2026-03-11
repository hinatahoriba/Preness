class AddSkippedToAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :answers, :skipped, :boolean, default: false, null: false
  end
end
