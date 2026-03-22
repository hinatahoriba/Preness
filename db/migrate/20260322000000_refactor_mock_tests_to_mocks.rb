# frozen_string_literal: true

class RefactorMockTestsToMocks < ActiveRecord::Migration[8.0]
  def up
    # purchases の FK・インデックスを削除
    remove_foreign_key :purchases, :mock_tests
    remove_index :purchases, name: "index_purchases_on_mock_test_id"
    remove_index :purchases, name: "index_purchases_on_user_id_and_mock_test_id"

    # mock_test_id → mock_id にリネーム
    rename_column :purchases, :mock_test_id, :mock_id

    # 新しいインデックスと FK を追加
    add_index :purchases, :mock_id
    add_index :purchases, %i[user_id mock_id], unique: true
    add_foreign_key :purchases, :mocks

    # mocks に stripe_price_id を追加
    add_column :mocks, :stripe_price_id, :string

    # mock_tests テーブルを削除
    drop_table :mock_tests
  end

  def down
    create_table :mock_tests do |t|
      t.string :title, null: false
      t.text :description
      t.integer :price_cents, null: false
      t.string :stripe_price_id
      t.string :difficulty, default: "medium", null: false
      t.integer :time_limit_minutes, default: 180, null: false
      t.boolean :published, default: false, null: false
      t.timestamps
    end
    add_index :mock_tests, :published

    remove_foreign_key :purchases, :mocks
    remove_index :purchases, name: "index_purchases_on_mock_id"
    remove_index :purchases, name: "index_purchases_on_user_id_and_mock_id"
    rename_column :purchases, :mock_id, :mock_test_id
    add_index :purchases, :mock_test_id
    add_index :purchases, %i[user_id mock_test_id], unique: true
    add_foreign_key :purchases, :mock_tests

    remove_column :mocks, :stripe_price_id
  end
end
