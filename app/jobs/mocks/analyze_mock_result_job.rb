module Mocks
  class AnalyzeMockResultJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    # Attempt が削除されていた場合はジョブを破棄
    discard_on ActiveRecord::RecordNotFound

    def perform(attempt_id)
      attempt = Attempt
        .includes(
          { mockable: { sections: { parts: { question_sets: :questions } } } },
          { answers: :question },
          { user: :user_profile }
        )
        .find(attempt_id)

      # レポートレコードを確保（冪等性：すでに完了していたらスキップ）
      report = AnalysisReport.find_or_create_by!(attempt: attempt)
      return if report.completed?

      begin
        payload = Mocks::BuildAnalysisPayload.call(attempt)
        result  = Mocks::AnalysisApiClient.call(payload)

        scores     = result["scores"] || {}
        narratives = result["narratives"] || {}

        report.update!(
          listening_score: scores["listening"],
          structure_score: scores["structure"],
          reading_score:   scores["reading"],
          total_score:     scores["total"],
          summary_closing: narratives["summary_closing"],
          strength:        narratives["strength"],
          challenge:       narratives["challenge"],
          status:          "completed"
        )

        Rails.logger.info "[AnalyzeMockResultJob] attempt_id=#{attempt_id} → completed"

      rescue => e
        report.update!(
          status:        "failed",
          error_message: "#{e.class}: #{e.message}",
          retry_count:   report.retry_count + 1
        )

        Rails.logger.error "[AnalyzeMockResultJob] attempt_id=#{attempt_id} failed: #{e.class} #{e.message}"

        raise  # SolidQueue のリトライを発火させるために再 raise
      end
    end
  end
end
