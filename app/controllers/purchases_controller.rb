class PurchasesController < ApplicationController
  before_action :authenticate_user!

  def create
    @mock = Mock.find(params[:mock_id])

    if current_user.purchases.completed.exists?(mock: @mock)
      redirect_to mypage_path, notice: "この模擬試験はすでに購入済みです。"
      return
    end

    session = Purchases::CreateCheckoutSession.call(user: current_user, mock: @mock)
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to mocks_path, alert: "決済の手続き中にエラーが発生しました: #{e.message}"
  end

  def success
    redirect_to mypage_path, notice: "購入が完了しました！模擬試験が受験できるようになりました。"
  end

  def cancel
    redirect_to mocks_path, alert: "購入がキャンセルされました。"
  end
end
