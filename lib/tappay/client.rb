require 'httparty'
require 'json'

module Tappay
  class Client
    include HTTParty

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    private

    def post(url, data)
      response = self.class.post(
        url,
        body: data.to_json,
        headers: headers,
        timeout: timeout
      )

      handle_response(response)
    rescue HTTParty::Error => e
      raise ConnectionError, "HTTP Request failed: #{e.message}"
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'x-api-key' => Tappay.configuration.partner_key
      }
    end

    def timeout
      25 # seconds
    end

    def handle_response(response)
      case response.code
      when 200
        parse_response(response)
      when 400
        raise ValidationError, "Invalid request: #{response.body}"
      when 401
        raise ConfigurationError, "Authentication failed. Check your partner_key."
      when 404
        raise ConnectionError, "API endpoint not found: #{response.request.last_uri}"
      else
        raise ConnectionError, "HTTP Request failed with code #{response.code}: #{response.body}"
      end
    end

    def parse_response(response)
      data = JSON.parse(response.body)
      
      unless data['status'].zero?
        raise APIError.new(data['status'], data['msg'])
      end
      
      data
    rescue JSON::ParserError => e
      raise ConnectionError, "Invalid JSON response: #{e.message}"
    end
  end
end
