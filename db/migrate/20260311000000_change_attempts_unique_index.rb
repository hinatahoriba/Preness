# frozen_string_literal: true

class ChangeAttemptsUniqueIndex < ActiveRecord::Migration[8.0]
  def up
    # 既存のユニークインデックスを削除
    remove_index :attempts, %i[user_id mockable_type mockable_id]

    # Mock のみユニーク制約を維持（部分インデックス）
    add_index :attempts, %i[user_id mockable_type mockable_id],
              unique: true,
              where: "mockable_type = 'Mock'",
              name: "index_attempts_on_user_id_and_mock"

    # Exercise のクエリ用インデックス
    add_index :attempts, %i[user_id mockable_type mockable_id],
              name: "index_attempts_on_user_id_and_mockable"
  end

  def down
    remove_index :attempts, name: "index_attempts_on_user_id_and_mock"
    remove_index :attempts, name: "index_attempts_on_user_id_and_mockable"

    add_index :attempts, %i[user_id mockable_type mockable_id], unique: true
  end
end
