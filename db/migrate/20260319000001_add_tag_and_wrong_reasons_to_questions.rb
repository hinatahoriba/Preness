class AddTagAndWrongReasonsToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :tag, :string
    add_column :questions, :wrong_reason_a, :text
    add_column :questions, :wrong_reason_b, :text
    add_column :questions, :wrong_reason_c, :text
    add_column :questions, :wrong_reason_d, :text
  end
end
