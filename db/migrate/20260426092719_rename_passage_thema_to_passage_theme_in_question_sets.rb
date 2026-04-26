class RenamePassageThemaToPassageThemeInQuestionSets < ActiveRecord::Migration[8.0]
  def change
    rename_column :question_sets, :passage_thema, :passage_theme
  end
end
