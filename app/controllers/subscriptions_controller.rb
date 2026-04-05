class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def checkout
    session = Subscriptions::CreateCheckoutSession.call(user: current_user)
    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    redirect_to subscriptions_path, alert: "サブスクリプションの手続き中にエラーが発生しました: #{e.message}", status: :see_other
  end

  def success
    redirect_to mypage_path, notice: "プレミアムプランへの登録が完了しました！"
  end

  def cancel
    redirect_to subscriptions_path, alert: "登録がキャンセルされました。"
  end
end
