module Api
  module V1
    class BaseController < ActionController::API
      before_action :restrict_content_source_ip!

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

      def restrict_content_source_ip!
        allowed_ips = ENV.fetch("ALLOWED_CONTENT_SOURCE_IPS", "")
          .split(",")
          .map(&:strip)
          .reject(&:blank?)

        return if allowed_ips.empty?

        return if allowed_ips.include?(request.remote_ip)

        render json: { status: "error", errors: ["Forbidden"] }, status: :forbidden
      end
    end
  end
end
