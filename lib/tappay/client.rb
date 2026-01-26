require 'net/http'
require 'uri'
require 'json'

module Tappay
  class Client
    attr_reader :options

    def initialize(options = {})
      @options = options
      @timeout = options.fetch(:timeout, 25)
    end

    def post(url, data)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = timeout
      http.read_timeout = timeout

      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.body = data.to_json

      @response = http.request(request)
      validate_response
      Response.new(@response)
    rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
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
      code = @response.code.to_i
      case code
      when 200
        true
      when 400
        raise ValidationError, "Invalid request: #{@response.body}"
      when 401
        raise ConfigurationError, "Authentication failed. Check your partner_key."
      when 404
        raise ConnectionError, "API endpoint not found"
      else
        raise ConnectionError, "HTTP Request failed with code #{code}: #{@response.body}"
      end
    end
  end

  class Response
    attr_reader :code, :body, :headers

    def initialize(net_http_response)
      @response = net_http_response
      @code = net_http_response.code.to_i
      @body = net_http_response.body
      @headers = net_http_response.to_hash
    end

    def parsed_response
      @parsed_response ||= JSON.parse(@body)
    rescue JSON::ParserError
      @body
    end

    def success?
      @code >= 200 && @code < 300
    end

    def [](key)
      parsed_response[key]
    end
  end
end
