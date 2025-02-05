require 'json'

module Tappay
  module ApplePay
    class Pay < PaymentBase

      def endpoint_url
        Tappay::Endpoints::Payment.pay_by_prime_url
      end

      private

      def get_merchant_id
        return nil if Tappay.configuration.merchant_group_id

        Tappay.configuration.apple_pay_merchant_id || super
      end

      def additional_required_options
        [:prime, :cardholder]
      end

      protected

      def payment_data
        super.merge(
          prime: options[:prime]
        )
      end
    end
  end
end
