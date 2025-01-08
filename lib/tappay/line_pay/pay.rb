# frozen_string_literal: true

require 'tappay/payment_base'

module Tappay
  module LinePay
    class Pay < PaymentBase
      def endpoint_url
        Tappay::Endpoints::Payment.pay_by_prime_url
      end

      private

      def get_merchant_id
        # If merchant_group_id is set, it takes precedence
        return nil if Tappay.configuration.merchant_group_id

        # Otherwise, use line_pay_merchant_id or fall back to default merchant_id
        Tappay.configuration.line_pay_merchant_id || super
      end

      def additional_required_options
        [:prime, :frontend_redirect_url, :backend_notify_url]
      end

      protected

      def payment_data
        super.merge(
          prime: options[:prime],
          result_url: {
            frontend_redirect_url: options[:frontend_redirect_url],
            backend_notify_url: options[:backend_notify_url]
          }
        )
      end
    end
  end
end
