module Tappay
  class Error < StandardError; end
  
  class ConfigurationError < Error; end
  class ConnectionError < Error; end
  class ValidationError < Error; end
  class PaymentError < Error; end
  class RefundError < Error; end
  class QueryError < Error; end
  
  class APIError < Error
    attr_reader :code, :message, :response_data

    def initialize(code, message, response_data = nil)
      @code = code
      @message = message
      @response_data = response_data
      super("TapPay API Error (#{code}): #{message}")
    end
  end
end
