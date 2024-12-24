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
    end

    module CreditCard
      class << self
        def payment_by_prime_url
          "#{Endpoints.base_url}/tpc/payment/pay-by-prime"
        end
        alias_method :instalment_by_prime_url, :payment_by_prime_url

        def payment_by_token_url
          "#{Endpoints.base_url}/tpc/payment/pay-by-token"
        end
        alias_method :instalment_by_token_url, :payment_by_token_url

        def refund_url
          "#{Endpoints.base_url}/tpc/transaction/refund"
        end
      end
    end

    module Transaction
      class << self
        def query_url
          "#{Endpoints.base_url}/tpc/transaction/query"
        end

        def trade_history_url
          "#{Endpoints.base_url}/tpc/transaction/trade-history"
        end

        def cap_url
          "#{Endpoints.base_url}/tpc/transaction/cap"
        end
      end
    end

    module Bind
      class << self
        def bind_card_url
          "#{Endpoints.base_url}/tpc/card/bind"
        end

        def remove_card_url
          "#{Endpoints.base_url}/tpc/card/remove"
        end
      end
    end
  end
end
