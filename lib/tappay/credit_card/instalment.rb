module Tappay
  module CreditCard
    class InstalmentBase < Client
      def initialize(options = {})
        super
        validate_instalment_options!
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
          three_domain_secure: options[:three_domain_secure] || false,
          instalment: options[:instalment]
        }
      end

      def validate_options!
        required = [:amount, :details]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end

      def validate_instalment_options!
        unless options[:instalment].to_i.between?(1, 12)
          raise ValidationError, "Invalid instalment value. Must be between 1 and 12"
        end
      end
    end

    class Instalment
      def self.by_prime(options = {})
        InstalmentByPrime.new(options)
      end

      def self.by_token(options = {})
        InstalmentByToken.new(options)
      end
    end

    class InstalmentByPrime < InstalmentBase
      def payment_data
        super.merge(
          prime: options[:prime],
          remember: options[:remember] || false,
          cardholder: card_holder_data
        )
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.instalment_url
      end

      def validate_options!
        super
        required = [:prime, :cardholder]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end

      def card_holder_data
        case options[:cardholder]
        when CardHolder
          options[:cardholder].to_h
        when Hash
          options[:cardholder]
        else
          raise ValidationError, "Invalid cardholder format"
        end
      end
    end

    class InstalmentByToken < InstalmentBase
      def payment_data
        super.merge(
          card_key: options[:card_key],
          card_token: options[:card_token],
          ccv_prime: options[:ccv_prime]
        )
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.instalment_url
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
