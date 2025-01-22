# frozen_string_literal: true

require 'tappay/payment_base'

module Tappay
  module CreditCard
    class Instalment < PaymentBase
      def self.by_prime(options = {})
        InstalmentByPrime.new(options)
      end

      def self.by_token(options = {})
        InstalmentByToken.new(options)
      end
    end

    class InstalmentByPrime < PaymentBase
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
        [:prime, :instalment]
      end
    end

    class InstalmentByToken < PaymentBase
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
        [:card_key, :card_token, :instalment]
      end
    end
  end
end
