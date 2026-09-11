module Tappay
  class Error < StandardError; end

  class ConfigurationError < Error; end
  class ConnectionError < Error; end
  class ValidationError < Error; end
end
