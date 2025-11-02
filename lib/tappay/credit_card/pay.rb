# frozen_string_literal: true

require 'tappay/payment_base'

module Tappay
  module CreditCard
    class Pay < PaymentBase
      def self.by_prime(options = {})
        PayByPrime.new(options)
      end

      def self.by_token(options = {})
        PayByToken.new(options)
      end
    end

    class PayByPrime < PaymentBase
      def payment_data
        super.merge(
          prime: options[:prime],
          remember: options[:remember] || false
        )
      end

      def endpoint_url
        Tappay::Endpoints::Payment.pay_by_prime_url
      end

      private

      def additional_required_options
        [:prime]
      end
    end

    class PayByToken < PaymentBase
      def payment_data
        super.merge(
          card_key: options[:card_key],
          card_token: options[:card_token],
          ccv_prime: options[:ccv_prime]
        )
      end

      def endpoint_url
        Tappay::Endpoints::Payment.pay_by_token_url
      end

      private

      def additional_required_options
        [:card_key, :card_token, :currency]
      end
    end
  end
end
