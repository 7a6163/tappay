module Tappay
  module CreditCard
    class Pay < Client
      def self.by_prime(options = {})
        PayByPrime.new(options)
      end

      def self.by_token(options = {})
        PayByToken.new(options)
      end
    end

    class PayByPrime < Client
      def initialize(options = {})
        super
        validate_options!
      end

      def execute
        post(Tappay::Endpoints::CreditCard.pay_by_prime_url, payment_data)
      end

      private

      def payment_data
        {
          partner_key: Tappay.configuration.partner_key,
          merchant_id: Tappay.configuration.merchant_id,
          prime: options[:prime],
          amount: options[:amount],
          details: options[:details],
          currency: options[:currency] || 'TWD',
          order_number: options[:order_number],
          redirect_url: options[:redirect_url],
          three_domain_secure: options[:three_domain_secure] || false,
          remember: options[:remember] || false,
          card_holder: card_holder_data
        }
      end

      def card_holder_data
        return unless options[:card_holder]

        case options[:card_holder]
        when CardHolder
          options[:card_holder].to_h
        when Hash
          options[:card_holder]
        else
          raise ValidationError, "Invalid card_holder format"
        end
      end

      def validate_options!
        required = [:prime, :amount, :details]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end
    end

    class PayByToken < Client
      def initialize(options = {})
        super
        validate_options!
      end

      def execute
        post(Tappay::Endpoints::CreditCard.pay_by_token_url, payment_data)
      end

      private

      def payment_data
        {
          partner_key: Tappay.configuration.partner_key,
          merchant_id: Tappay.configuration.merchant_id,
          card_key: options[:card_key],
          card_token: options[:card_token],
          amount: options[:amount],
          details: options[:details],
          currency: options[:currency],
          order_number: options[:order_number],
          redirect_url: options[:redirect_url],
          three_domain_secure: options[:three_domain_secure] || false,
          card_holder: card_holder_data
        }
      end

      def card_holder_data
        return unless options[:card_holder]

        case options[:card_holder]
        when CardHolder
          options[:card_holder].to_h
        when Hash
          options[:card_holder]
        else
          raise ValidationError, "Invalid card_holder format"
        end
      end

      def validate_options!
        required = [:card_key, :card_token, :amount, :details, :currency]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end
    end
  end
end
