module AnalysisFailureNotifiable
  private

  def notify_analysis_failure(error)
    attempt_id = arguments.first
    report = AnalysisReport
      .includes(attempt: [:user, :mockable])
      .find_by(attempt_id: attempt_id)

    unless report
      Rails.logger.error "[#{self.class.name}] analysis failure notification skipped: report not found for attempt_id=#{attempt_id}"
      return
    end

    AnalysisFailureMailer.failed(
      report,
      job_name: self.class.name,
      error_class: error.class.name,
      error_message: error.message,
      backtrace: Array(error.backtrace).first(10)
    ).deliver_now
  rescue => notification_error
    Rails.logger.error(
      "[#{self.class.name}] analysis failure notification failed: " \
      "#{notification_error.class} #{notification_error.message}"
    )
  end
end
