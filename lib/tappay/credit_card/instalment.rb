module Tappay
  module CreditCard
    class Instalment
      def self.by_prime(options = {})
        InstalmentByPrime.new(options)
      end

      def self.by_token(options = {})
        InstalmentByToken.new(options)
      end
    end

    class InstalmentByPrime < PaymentBase
      def initialize(options = {})
        super(options)
      end

      def payment_data
        super.merge(
          prime: options[:prime],
          remember: options[:remember] || false
        )
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.payment_by_prime_url
      end

      private

      def additional_required_options
        [:prime, :cardholder, :instalment]
      end
    end

    class InstalmentByToken < PaymentBase
      def initialize(options = {})
        super(options)
      end

      def payment_data
        super.merge(
          card_key: options[:card_key],
          card_token: options[:card_token],
          ccv_prime: options[:ccv_prime]
        )
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.payment_by_token_url
      end

      private

      def additional_required_options
        [:card_key, :card_token, :instalment]
      end
    end
  end
end
