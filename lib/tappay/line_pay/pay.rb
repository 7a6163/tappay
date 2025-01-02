# frozen_string_literal: true

require 'tappay/payment_base'

module Tappay
  module LinePay
    class Pay < PaymentBase
      def payment_data
        super.merge(
          prime: options[:prime],
          result_url: {
            frontend_redirect_url: options[:frontend_redirect_url],
            backend_notify_url: options[:backend_notify_url]
          },
          remember: options[:remember] || false
        )
      end

      def endpoint_url
        Tappay::Endpoints::Payment.pay_by_prime_url
      end

      private

      def get_merchant_id
        Tappay.configuration.line_pay_merchant_id || super
      end

      def additional_required_options
        [:prime, :frontend_redirect_url, :backend_notify_url]
      end
    end
  end
end