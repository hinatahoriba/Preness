class AddPassageThemaToQuestionSets < ActiveRecord::Migration[8.0]
  def change
    add_column :question_sets, :passage_thema, :string
  end
end
