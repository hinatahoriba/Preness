module Mocks
  class SendAnalysisCompletedMailJob < ApplicationJob
    queue_as :default

    discard_on ActiveRecord::RecordNotFound

    def perform(report_id)
      report = AnalysisReport.includes(attempt: [:user, :mockable]).find(report_id)
      MockAnalysisMailer.completed(report).deliver_now
    end
  end
end
