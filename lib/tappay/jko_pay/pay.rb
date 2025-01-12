# frozen_string_literal: true

module Tappay
  module JkoPay
    class Pay < PaymentBase
      def endpoint_url
        Endpoints::Payment.pay_by_prime_url
      end

      private

      def get_merchant_id
        # If merchant_group_id is set, it takes precedence
        return nil if Tappay.configuration.merchant_group_id

        # Otherwise, use jko_pay_merchant_id or fall back to default merchant_id
        Tappay.configuration.jko_pay_merchant_id || super
      end

      def additional_required_options
        [:prime, :frontend_redirect_url, :backend_notify_url]
      end

      protected

      def payment_data
        data = super
        data[:result_url] = {
          frontend_redirect_url: options[:frontend_redirect_url],
          backend_notify_url: options[:backend_notify_url]
        }
        data[:prime] = options[:prime]
        data
      end
    end
  end
end
