# frozen_string_literal: true

require 'csv'
require 'json'
require 'net/http'
require 'uri'

require_relative "tappay/version"
require_relative "tappay/configuration"
require_relative "tappay/client"
require_relative "tappay/errors"
require_relative "tappay/refund"
require_relative "tappay/payment_base"
require_relative "tappay/card_holder"
require_relative "tappay/endpoints"
require_relative "tappay/transaction/query"
require_relative "tappay/credit_card/pay"
require_relative "tappay/credit_card/instalment"
require_relative "tappay/line_pay/pay"
require_relative "tappay/jko_pay/pay"
require_relative "tappay/apple_pay/pay"
require_relative "tappay/google_pay/pay"

module Tappay
  class Error < StandardError; end
  class ValidationError < Error; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end

    def reset
      self.configuration = Configuration.new
    end
  end
end
