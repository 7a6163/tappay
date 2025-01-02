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

    module CreditCard
      class << self
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

    module LinePay
      class << self
        def redirect_url
          "#{Endpoints.base_url}/tpc/payment/redirect"
        end

        def query_url
          "#{Endpoints.base_url}/tpc/transaction/query"
        end
      end
    end
  end
end
