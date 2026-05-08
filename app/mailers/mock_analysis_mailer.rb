class MockAnalysisMailer < ApplicationMailer
  def completed(report)
    @report  = report
    @attempt = report.attempt
    @user    = @attempt.user
    @mock    = @attempt.mockable

    mail(
      to:      @user.email,
      subject: "【Preness】模擬試験の分析レポートが完成しました"
    )
  end
end
