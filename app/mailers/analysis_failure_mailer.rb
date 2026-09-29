class AnalysisFailureMailer < ApplicationMailer
  def failed(report, job_name:, error_class:, error_message:, backtrace:)
    @report = report
    @attempt = report.attempt
    @user = @attempt.user
    @mockable = @attempt.mockable
    @job_name = job_name
    @error_class = error_class
    @error_message = error_message
    @backtrace = backtrace

    mail(
      to: developer_notification_email,
      subject: "【Preness】分析レポート生成に失敗しました"
    )
  end

  private

  def developer_notification_email
    ENV.fetch("DEVELOPER_NOTIFICATION_EMAIL") do
      ENV.fetch("MAILER_FROM_ADDRESS", "no-reply@preness-app.com")
    end
  end
end
