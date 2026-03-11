module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      rescue_from ActionController::ParameterMissing do |e|
        render json: { status: "error", errors: [e.message] }, status: :unprocessable_entity
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { status: "error", errors: [e.message] }, status: :unprocessable_entity
      end

      rescue_from KeyError do |e|
        render json: { status: "error", errors: ["Parameter missing: #{e.key}"] }, status: :unprocessable_entity
      end

      private

      API_KEY_ENV = "CONTENT_SOURCE_API_KEY"

      def authenticate_api_key!
        expected = ENV[API_KEY_ENV].to_s

        if expected.blank?
          Rails.logger.error("[API Auth] #{API_KEY_ENV} is not set")
          render json: { status: "error", errors: ["Server misconfigured"] }, status: :internal_server_error
          return
        end

        provided = extract_api_key

        unless provided.present? && secure_compare(provided, expected)
          render json: { status: "error", errors: ["Unauthorized"] }, status: :unauthorized
        end
      end

      def extract_api_key
        auth = request.authorization.to_s.strip

        if auth.start_with?("Bearer ")
          return auth.delete_prefix("Bearer ").strip
        end

        return auth if auth.present?

        request.headers["X-Api-Key"].to_s.strip.presence
      end

      def secure_compare(a, b)
        ActiveSupport::SecurityUtils.secure_compare(
          ::Digest::SHA256.hexdigest(a),
          ::Digest::SHA256.hexdigest(b)
        )
      end
    end
  end
end
