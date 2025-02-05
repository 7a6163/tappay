module Tappay
  class Error < StandardError; end

  class ConfigurationError < Error; end
  class ConnectionError < Error; end
  class ValidationError < Error; end
  class PaymentError < Error; end
  class RefundError < Error; end
  class QueryError < Error; end
end
