class DiagnosticAnalysisMailer < ApplicationMailer
  def completed(report)
    @report  = report
    @attempt = report.attempt
    @user    = @attempt.user
    @diagnostic = @attempt.mockable

    mail(
      to:      @user.email,
      subject: "【Preness】実力診断の分析レポートが完成しました"
    )
  end
end
