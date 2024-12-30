module Tappay
  module CreditCard
    class PaymentBase < Client
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
          data[:instalment] = options[:instalment] if options[:instalment]
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
        required = base_required_options + additional_required_options
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?

        validate_instalment! if options[:instalment]
      end

      private

      def base_required_options
        [:amount, :details]
      end

      def additional_required_options
        []
      end

      def validate_instalment!
        unless options[:instalment].to_i.between?(1, 12)
          raise ValidationError, "Invalid instalment value. Must be between 1 and 12"
        end
      end
    end

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
        Tappay::Endpoints::CreditCard.payment_by_prime_url
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
          card_token: options[:card_token]
        )
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.payment_by_token_url
      end

      private

      def additional_required_options
        [:card_key, :card_token, :currency]
      end
    end
  end
end
