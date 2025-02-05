require 'httparty'
require 'json'

module Tappay
  class Client
    include HTTParty

    attr_reader :options

    def initialize(options = {})
      @options = options
      @timeout = options.fetch(:timeout, 25)
    end

    def post(url, data)
      @response = self.class.post(
        url,
        body: data.to_json,
        headers: headers,
        timeout: timeout
      )

      validate_response
      @response
    rescue HTTParty::Error, Timeout::Error, Net::OpenTimeout => e
      raise ConnectionError, "HTTP Request failed: #{e.message}"
    end

    private

    def headers
      {
        'Content-Type' => 'application/json',
        'x-api-key' => Tappay.configuration.partner_key
      }
    end

    def timeout
      @timeout
    end

    def validate_response
      case @response.code
      when 200
        true
      when 400
        raise ValidationError, "Invalid request: #{@response.body}"
      when 401
        raise ConfigurationError, "Authentication failed. Check your partner_key."
      when 404
        raise ConnectionError, "API endpoint not found: #{@response.request.last_uri}"
      else
        raise ConnectionError, "HTTP Request failed with code #{@response.code}: #{@response.body}"
      end
    end
  end
end
