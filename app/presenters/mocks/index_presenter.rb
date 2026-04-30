module Mocks
  class IndexPresenter
    def initialize(mocks:, attempts_by_mock_id:, purchased_mock_ids:)
      @mocks = mocks
      @attempts_by_mock_id = attempts_by_mock_id
      @purchased_mock_ids = purchased_mock_ids
    end

    def cards
      @mocks.map do |mock|
        attempt = @attempts_by_mock_id[mock.id]
        purchased = @purchased_mock_ids.include?(mock.id)

        {
          mock: mock,
          badge: badge_for(purchased: purchased, attempt: attempt),
          attempt_date: attempt&.completed_at&.strftime("%Y年%m月%d日"),
          interrupted: purchased && attempt.present? && attempt.completed_at.blank?,
          action: action_for(mock: mock, purchased: purchased, attempt: attempt)
        }
      end
    end

    private

    def badge_for(purchased:, attempt:)
      if !purchased
        { label: "未購入", class: "bg-amber-50 text-amber-600" }
      elsif attempt&.completed_at
        { label: "完了", class: "bg-green-50 text-green-600" }
      elsif attempt
        { label: "中断", class: "bg-red-50 text-red-600" }
      else
        { label: "購入済み", class: "bg-blue-50 text-blue-600" }
      end
    end

    def action_for(mock:, purchased:, attempt:)
      if !purchased
        {
          type: :purchase,
          path: checkouts_path(mock_id: mock.id),
          method: :post,
          label: "購入する",
          class: "w-full bg-amber-500 hover:bg-amber-600 text-white py-3 rounded-2xl text-sm font-bold flex items-center justify-center space-x-2 transition-all shadow-lg hover:shadow-amber-500/30"
        }
      elsif attempt&.completed_at
        {
          type: :link,
          path: result_mock_path(mock, attempt_id: attempt.id),
          label: "結果を確認する",
          class: "w-full bg-white border-2 border-gray-100 text-gray-700 hover:border-[#34a0a4] hover:text-[#34a0a4] py-3 rounded-2xl text-sm font-bold flex items-center justify-center space-x-2 transition-all shadow-sm"
        }
      elsif attempt
        {
          type: :disabled,
          label: "中断（再開できません）",
          class: "w-full bg-gray-100 text-gray-500 py-3 rounded-2xl text-sm font-bold flex items-center justify-center space-x-2 cursor-not-allowed select-none"
        }
      else
        {
          type: :link,
          path: guideline_mock_path(mock),
          label: "受験を開始する",
          class: "w-full bg-[#34a0a4] hover:bg-[#2d8b8e] text-white py-3 rounded-2xl text-sm font-bold flex items-center justify-center space-x-2 transition-all shadow-lg hover:shadow-[#34a0a4]/30"
        }
      end
    end

    def checkouts_path(mock_id:)
      Rails.application.routes.url_helpers.checkouts_path(mock_id: mock_id)
    end

    def result_mock_path(mock, attempt_id:)
      Rails.application.routes.url_helpers.result_mock_path(mock, attempt_id: attempt_id)
    end

    def guideline_mock_path(mock)
      Rails.application.routes.url_helpers.guideline_mock_path(mock)
    end
  end
end
