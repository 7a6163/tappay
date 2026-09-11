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
      # to_s so that a nil body raises JSON::ParserError rather than the
      # TypeError JSON.parse(nil) would raise past this rescue.
      @parsed_response ||= JSON.parse(@body.to_s)
    rescue JSON::ParserError
      @body
    end

    # TapPay signals business failures (declined card, insufficient funds,
    # expired card) with HTTP 200 and a non-zero `status`, so the HTTP code
    # alone says nothing. Client only builds a Response once validate_response
    # has accepted the HTTP code, so `status` is the only question left.
    #
    # This means "TapPay processed the request", not "the money moved": for a
    # credit card the transaction is authorised but capture is asynchronous,
    # and for LINE Pay / JKO Pay / iPass Money it means only that a payment_url
    # was created and the customer has yet to pay. Confirm with Transaction::Query.
    def success?
      parsed_response.is_a?(Hash) && parsed_response['status'] == 0
    end

    def [](key)
      parsed_response[key]
    end
  end
end
