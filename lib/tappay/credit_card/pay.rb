module Tappay
  module CreditCard
    class PayBase < Client
      def initialize(options = {})
        super
        validate_options!
      end

      def execute
        post(endpoint_url, payment_data)
      end

      protected

      def endpoint_url
        raise NotImplementedError, "Subclass must implement abstract method 'endpoint_url'"
      end

      def payment_data
        {
          partner_key: Tappay.configuration.partner_key,
          merchant_id: options[:merchant_id] || Tappay.configuration.merchant_id,
          amount: options[:amount],
          details: options[:details],
          currency: options[:currency] || 'TWD',
          order_number: options[:order_number],
          redirect_url: options[:redirect_url],
          three_domain_secure: options[:three_domain_secure] || false
        }.tap do |data|
          data[:cardholder] = card_holder_data if options[:cardholder]
        end
      end

      def card_holder_data
        return nil unless options[:cardholder]

        case options[:cardholder]
        when CardHolder
          options[:cardholder].to_h
        when Hash
          options[:cardholder]
        else
          raise ValidationError, "Invalid cardholder format"
        end
      end

      def validate_options!
        required = [:amount, :details]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end
    end

    class Pay < PayBase
      def self.by_prime(options = {})
        PayByPrime.new(options)
      end

      def self.by_token(options = {})
        PayByToken.new(options)
      end
    end

    class PayByPrime < PayBase
      def payment_data
        data = super.merge(
          prime: options[:prime],
          remember: options[:remember] || false
        )
        data[:cardholder] = card_holder_data if card_holder_data
        data
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.pay_by_prime_url
      end

      def validate_options!
        super
        required = [:prime]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end
    end

    class PayByToken < PayBase
      def payment_data
        super.merge(
          card_key: options[:card_key],
          card_token: options[:card_token]
        )
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.pay_by_token_url
      end

      def validate_options!
        super
        required = [:card_key, :card_token, :currency]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end
    end
  end
end
