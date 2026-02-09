class CreateUserExams < ActiveRecord::Migration[8.0]
  def change
    create_table :user_exams do |t|
      t.references :user, null: false, foreign_key: true
      t.references :exam, null: false, foreign_key: true
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.string :status, null: false, default: "pending"
      t.datetime :paid_at

      t.timestamps null: false
    end

    add_index :user_exams, [ :user_id, :exam_id ], unique: true
    add_index :user_exams, :stripe_checkout_session_id
    add_index :user_exams, :stripe_payment_intent_id
    add_index :user_exams, :status
    add_check_constraint :user_exams, "status IN ('pending', 'paid', 'failed')", name: "user_exams_status_check"
  end
end
