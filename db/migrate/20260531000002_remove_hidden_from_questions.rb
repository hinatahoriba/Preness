class RemoveHiddenFromQuestions < ActiveRecord::Migration[8.0]
  def change
    remove_column :questions, :hidden, :boolean
  end
end
