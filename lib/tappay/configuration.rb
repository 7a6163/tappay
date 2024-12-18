module Tappay
  class Configuration
    attr_accessor :partner_key, :merchant_id, :instalment_merchant_id, :sandbox
    attr_writer :api_version

    def initialize
      @sandbox = true
      @api_version = '2'
    end

    def api_version
      @api_version.to_s
    end

    def base_url
      if sandbox
        'https://sandbox.tappaysdk.com/tpc'
      else
        'https://prod.tappaysdk.com/tpc'
      end
    end

    def prime_url
      "#{base_url}/payment/pay-by-prime"
    end

    def token_url
      "#{base_url}/payment/pay-by-token"
    end

    def query_url
      "#{base_url}/transaction/query"
    end

    def refund_url
      "#{base_url}/transaction/refund"
    end
  end
end
