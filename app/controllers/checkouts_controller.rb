class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  # POST /checkouts
  def create
    mock = Mock.find(params[:mock_id])

    # 既に購入済みの場合はリダイレクト
    if current_user.purchased?(mock)
      redirect_to guideline_mock_path(mock), notice: "この模擬試験は既に購入済みです。"
      return
    end

    # 以前の未完了の購入レコードを削除
    current_user.purchases.where(mock: mock, status: "pending").destroy_all

    session = Stripe::Checkout::Session.create(
      customer_email: current_user.email,
      payment_method_types: ["card"],
      line_items: [{
        price: ENV["STRIPE_EXAM_PRICE_ID"],
        quantity: 1
      }],
      mode: "payment",
      success_url: success_checkouts_url(mock_id: mock.id, session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: cancel_checkouts_url(mock_id: mock.id),
      metadata: {
        user_id: current_user.id,
        mock_id: mock.id
      }
    )

    # pending 状態で Purchase を作成
    Purchase.create!(
      user: current_user,
      mock: mock,
      stripe_checkout_session_id: session.id,
      status: "pending"
    )

    redirect_to session.url, allow_other_host: true
  end

  # GET /checkouts/success?mock_id=X
  def success
    @mock = Mock.find(params[:mock_id])
    @purchase = current_user.purchases.find_by(mock: @mock)
  end

  # GET /checkouts/cancel?mock_id=X
  def cancel
    @mock = Mock.find(params[:mock_id])
    # pending の Purchase を削除
    purchase = current_user.purchases.find_by(mock: @mock, status: "pending")
    purchase&.destroy
  end
end
