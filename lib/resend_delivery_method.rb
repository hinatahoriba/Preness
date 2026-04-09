require "json"
require "net/http"
require "uri"

class ResendDeliveryMethod
  API_ENDPOINT = "https://api.resend.com/emails".freeze

  def initialize(settings = {})
    @api_key = settings[:api_key] || ENV["RESEND_API_KEY"]
    @api_endpoint = settings[:api_endpoint] || API_ENDPOINT
    @open_timeout = settings.fetch(:open_timeout, 5)
    @read_timeout = settings.fetch(:read_timeout, 10)
  end

  def deliver!(mail)
    raise ArgumentError, "RESEND_API_KEY is not configured" if @api_key.blank?

    payload = {
      from: mail[:from]&.value,
      to: Array(mail.to),
      cc: Array(mail.cc).presence,
      bcc: Array(mail.bcc).presence,
      reply_to: Array(mail.reply_to).presence,
      subject: mail.subject
    }.compact

    html_body = html_content(mail)
    text_body = text_content(mail)

    payload[:html] = html_body if html_body.present?
    payload[:text] = text_body if text_body.present?

    response = http_client(request_uri).start do |http|
      request = Net::HTTP::Post.new(request_uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)
      http.request(request)
    end

    return if response.is_a?(Net::HTTPSuccess)

    raise_delivery_error!(response)
  end

  private

  def html_content(mail)
    return mail.html_part.body.decoded if mail.html_part.present?
    return mail.body.decoded if mail.mime_type == "text/html"

    nil
  end

  def text_content(mail)
    return mail.text_part.body.decoded if mail.text_part.present?
    return mail.body.decoded if mail.mime_type == "text/plain"

    nil
  end

  def request_uri
    @request_uri ||= URI.parse(@api_endpoint)
  end

  def http_client(uri)
    Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout
    end
  end

  def raise_delivery_error!(response)
    body = response.body.presence || "empty response body"
    raise StandardError, "Resend API error #{response.code}: #{body}"
  end
end
