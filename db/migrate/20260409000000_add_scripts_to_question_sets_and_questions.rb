# frozen_string_literal: true

class AddScriptsToQuestionSetsAndQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :question_sets, :scripts, :jsonb
    remove_column :question_sets, :conversation_text, :text

    add_column :questions, :scripts, :jsonb
  end
end
