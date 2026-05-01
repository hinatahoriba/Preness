module Mocks
  # 外部 FastAPI に分析リクエストを POST し、レスポンスを返すクライアント
  class AnalysisApiClient
    class ApiError < StandardError; end

    def self.call(payload)
      new.call(payload)
    end

    def call(payload)
      conn = build_connection
      response = conn.post("/api/v1/analysis/jobs", payload)

      unless response.success?
        Rails.logger.error "[AnalysisApiClient] Error Status: #{response.status}, Body: #{response.body}"
        raise ApiError, "API responded with status #{response.status}: #{response.body}"
      end

      response.body
    end

    private

    def build_connection
      Faraday.new(url: base_url) do |f|
        f.request  :json           # Hash → JSON に自動変換
        f.response :json           # レスポンス body を Hash に自動パース
        f.response :raise_error    # 4xx/5xx で例外を自動 raise

        if ENV["ANALYSIS_API_KEY"].present?
          f.headers["X-Api-Key"] = ENV["ANALYSIS_API_KEY"]
        end

        f.options.open_timeout = 10  # 接続タイムアウト（秒）
        f.options.timeout      = 30  # 読み取りタイムアウト（秒）
      end
    end

    def base_url
      ENV.fetch("ANALYSIS_API_URL") do
        raise "ANALYSIS_API_URL is not set"
      end
    end
  end
end
