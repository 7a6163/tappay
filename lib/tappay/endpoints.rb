# frozen_string_literal: true

module Tappay
  module Endpoints
    class << self
      def base_url
        if Tappay.configuration.sandbox?
          'https://sandbox.tappaysdk.com'
        else
          'https://prod.tappaysdk.com'
        end
      end

      def refund_url
        "#{base_url}/tpc/transaction/refund"
      end
    end

    module Payment
      class << self
        def pay_by_prime_url
          "#{Endpoints.base_url}/tpc/payment/pay-by-prime"
        end

        def pay_by_token_url
          "#{Endpoints.base_url}/tpc/payment/pay-by-token"
        end
      end
    end

    module Transaction
      class << self
        def query_url
          "#{Endpoints.base_url}/tpc/transaction/query"
        end
      end
    end
  end
end
