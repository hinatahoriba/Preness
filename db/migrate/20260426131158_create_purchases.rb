class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :mock, null: false, foreign_key: true
      t.string :stripe_checkout_session_id, null: false
      t.string :stripe_payment_intent_id
      t.string :status, null: false, default: "pending"
      t.integer :amount_cents
      t.string :currency, default: "jpy"
      t.datetime :purchased_at

      t.timestamps
    end

    add_index :purchases, :stripe_checkout_session_id, unique: true
    add_index :purchases, [:user_id, :mock_id], unique: true
  end
end
