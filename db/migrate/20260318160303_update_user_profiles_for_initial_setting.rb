class UpdateUserProfilesForInitialSetting < ActiveRecord::Migration[8.0]
  def change
    # 旧カラムを削除
    remove_column :user_profiles, :full_name, :string
    remove_column :user_profiles, :full_name_kana, :string
    remove_column :user_profiles, :age, :integer
    remove_column :user_profiles, :data_usage_agreed, :boolean

    # 基本プロフィール
    add_column :user_profiles, :last_name, :string
    add_column :user_profiles, :first_name, :string
    add_column :user_profiles, :last_name_kana, :string
    add_column :user_profiles, :first_name_kana, :string
    add_column :user_profiles, :date_of_birth, :date

    # TOEFL ITP スコア（current は NULL 許容 = 受験経験なし）
    add_column :user_profiles, :itp_current_score, :integer
    add_column :user_profiles, :itp_target_score, :integer

    # 外部英語検定（全部 NULL = 資格なし）
    add_column :user_profiles, :eiken_grade, :string
    add_column :user_profiles, :toeic_score, :integer
    add_column :user_profiles, :toefl_ibt_score, :integer
    add_column :user_profiles, :ielts_score, :decimal, precision: 2, scale: 1
  end
end
