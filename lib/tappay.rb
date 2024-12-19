# frozen_string_literal: true

require_relative "tappay/version"
require_relative "tappay/configuration"
require_relative "tappay/client"
require_relative "tappay/errors"
require_relative "tappay/card_holder"
require_relative "tappay/transaction/query"

module Tappay
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.reset
    self.configuration = Configuration.new
  end
end
