require 'httparty'
require 'json'

module Tappay
  class Client
    include HTTParty

    attr_reader :options

    def initialize(options = {})
      @options = options
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
      25 # seconds
    end

    def validate_response
      case @response.code
      when 200
        data = parse_response
        status = data['status']
        # For transaction queries, status 2 means no records found, which is a valid response
        unless status.zero? || (status == 2 && @response.request.path.include?('/tpc/transaction/query'))
          raise APIError.new(data['status'], data['msg'])
        end
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

    def parse_response
      JSON.parse(@response.body)
    rescue JSON::ParserError => e
      raise ConnectionError, "Invalid JSON response: #{e.message}"
    end
  end
end
