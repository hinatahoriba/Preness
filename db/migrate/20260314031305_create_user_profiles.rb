class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :full_name
      t.string :full_name_kana
      t.string :nickname
      t.integer :age
      t.string :affiliation
      t.boolean :study_abroad_plan
      t.boolean :data_usage_agreed

      t.timestamps
    end
  end
end
