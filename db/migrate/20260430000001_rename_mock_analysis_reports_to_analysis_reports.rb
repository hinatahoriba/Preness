class RenameMockAnalysisReportsToAnalysisReports < ActiveRecord::Migration[8.0]
  def change
    rename_table :mock_analysis_reports, :analysis_reports
  end
end
