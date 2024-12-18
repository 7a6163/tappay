module Tappay
  class Error < StandardError; end
  
  class ConfigurationError < Error; end
  class ConnectionError < Error; end
  class ValidationError < Error; end
  class PaymentError < Error; end
  class RefundError < Error; end
  class QueryError < Error; end
  
  class APIError < Error
    attr_reader :code, :message

    def initialize(code, message)
      @code = code
      @message = message
      super("TapPay API Error (#{code}): #{message}")
    end
  end
end
