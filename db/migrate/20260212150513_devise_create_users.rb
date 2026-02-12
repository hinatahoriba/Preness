# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def up
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
      t.string :username, null: false
      t.boolean :terms_agreed, null: false, default: false
      t.timestamps null: false
    end unless table_exists?(:users)

    add_column :users, :username, :string, null: false, default: "" unless column_exists?(:users, :username)
    add_column :users, :terms_agreed, :boolean, null: false, default: false unless column_exists?(:users, :terms_agreed)

    add_column :users, :confirmation_token, :string unless column_exists?(:users, :confirmation_token)
    add_column :users, :confirmed_at, :datetime unless column_exists?(:users, :confirmed_at)
    add_column :users, :confirmation_sent_at, :datetime unless column_exists?(:users, :confirmation_sent_at)
    add_column :users, :unconfirmed_email, :string unless column_exists?(:users, :unconfirmed_email)

    add_index :users, :email, unique: true unless index_exists?(:users, :email, unique: true)
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token, unique: true)
    add_index :users, :confirmation_token, unique: true unless index_exists?(:users, :confirmation_token, unique: true)
  end

  def down
    drop_table :users, if_exists: true
  end
end
