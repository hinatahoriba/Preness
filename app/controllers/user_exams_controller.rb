class UserExamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_exam
  before_action :ensure_stripe_configured!, only: :create

  def create
    user_exam = current_user.user_exams.find_or_initialize_by(exam: @exam)

    if user_exam.paid?
      redirect_to exams_path, alert: "この模試は既に購入済みです。"
      return
    end

    user_exam.assign_attributes(
      status: :pending,
      paid_at: nil,
      stripe_checkout_session_id: nil,
      stripe_payment_intent_id: nil
    )
    user_exam.save! if user_exam.new_record? || user_exam.changed?

    session = Stripe::Checkout::Session.create(
      mode: "payment",
      customer_email: current_user.email,
      line_items: checkout_line_items(@exam),
      metadata: {
        user_exam_id: user_exam.id,
        user_id: current_user.id,
        exam_id: @exam.id
      },
      success_url: success_exam_purchase_url(@exam, session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: cancel_exam_purchase_url(@exam)
    )

    user_exam.update!(stripe_checkout_session_id: session.id)
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    user_exam&.update(status: :failed)
    redirect_to exams_path, alert: "決済の開始に失敗しました: #{e.message}"
  end

  def success
    user_exam = current_user.user_exams.find_by(exam: @exam)

    if user_exam&.paid?
      redirect_to exams_path, notice: "模試の購入が完了しました。"
    else
      redirect_to exams_path, notice: "決済は受け付け済みです。購入状態の反映まで数秒お待ちください。"
    end
  end

  def cancel
    user_exam = current_user.user_exams.find_by(exam: @exam)
    user_exam&.update(status: :failed) if user_exam&.pending?

    redirect_to exams_path, alert: "購入をキャンセルしました。"
  end

  private

  def set_exam
    @exam = Exam.find(params[:exam_id])
  end

  def ensure_stripe_configured!
    return if Rails.configuration.x.stripe.secret_key.present?

    redirect_to exams_path, alert: "STRIPE_SECRET_KEY が未設定です。"
  end

  def checkout_line_items(exam)
    return [ { price: exam.stripe_price_id, quantity: 1 } ] if exam.stripe_price_id.present?

    [
      {
        price_data: {
          currency: "jpy",
          product_data: {
            name: exam.title
          },
          unit_amount: exam.price
        },
        quantity: 1
      }
    ]
  end
end
