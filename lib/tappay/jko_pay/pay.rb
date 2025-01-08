# frozen_string_literal: true

module Tappay
  module JkoPay
    class Pay < PaymentBase
      def initialize(options = {})
        super
        validate_jko_pay_options!
      end

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

      def validate_jko_pay_options!
        validate_result_urls!
      end

      def validate_result_urls!
        raise ValidationError, 'frontend_redirect_url is required for JKO Pay' if options[:frontend_redirect_url].nil?
        raise ValidationError, 'backend_notify_url is required for JKO Pay' if options[:backend_notify_url].nil?
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
