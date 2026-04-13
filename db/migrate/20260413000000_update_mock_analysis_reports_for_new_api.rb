class UpdateMockAnalysisReportsForNewApi < ActiveRecord::Migration[8.0]
  def change
    rename_column :mock_analysis_reports, :overall,    :summary_closing
    rename_column :mock_analysis_reports, :strengths,  :strength
    rename_column :mock_analysis_reports, :challenges, :challenge

    add_column :mock_analysis_reports, :listening_score, :integer
    add_column :mock_analysis_reports, :structure_score, :integer
    add_column :mock_analysis_reports, :reading_score,   :integer
    add_column :mock_analysis_reports, :total_score,     :integer
  end
end
