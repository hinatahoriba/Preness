class AddHiddenToExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :exercises, :hidden, :boolean, default: false, null: false
  end
end
