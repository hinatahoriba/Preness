class CreateMockAnalysisReports < ActiveRecord::Migration[8.0]
  def change
    create_table :mock_analysis_reports do |t|
      t.references :attempt, null: false, foreign_key: true, index: { unique: true }
      t.text :overall        # 総評
      t.text :strengths      # 強み
      t.text :challenges     # 課題
      t.string :status, null: false, default: "pending"  # pending / completed / failed
      t.integer :retry_count, null: false, default: 0
      t.text :error_message  # 失敗時のエラー内容

      t.timestamps
    end

    add_index :mock_analysis_reports, :status
  end
end
