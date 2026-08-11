class CreateLineLinkSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :line_link_sessions do |t|
      t.string :line_user_id, null: false
      t.string :link_token, null: false
      t.string :nonce
      t.bigint :user_id
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :line_link_sessions, :link_token, unique: true
    add_index :line_link_sessions, :nonce, unique: true, where: "nonce IS NOT NULL"
    add_index :line_link_sessions, :line_user_id
    add_index :line_link_sessions, :user_id
    add_foreign_key :line_link_sessions, :users, column: :user_id
  end
end

