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
        # Check configuration conflicts first
        if Tappay.configuration.merchant_group_id && Tappay.configuration.merchant_id
          raise Tappay::ValidationError, "merchant_group_id and merchant_id cannot be used together"
        end

        # Get values from options
        opt_group_id = options[:merchant_group_id]
        opt_merchant_id = options[:merchant_id]

        # Check for conflicts in options
        if opt_group_id && opt_merchant_id
          raise Tappay::ValidationError, "merchant_group_id and merchant_id cannot be used together"
        end

        # If options has any ID, use it exclusively
        if opt_group_id || opt_merchant_id
          merchant_group_id = opt_group_id
          merchant_id = opt_merchant_id
        else
          # If no options, use configuration
          merchant_group_id = Tappay.configuration.merchant_group_id
          merchant_id = Tappay.configuration.merchant_id
        end

        # Check if at least one is provided
        unless merchant_group_id || merchant_id
          raise Tappay::ValidationError, "Either merchant_group_id or merchant_id must be provided"
        end

        {
          partner_key: Tappay.configuration.partner_key,
          amount: options[:amount],
          details: options[:details],
          currency: options[:currency] || 'TWD',
          order_number: options[:order_number],
          three_domain_secure: options[:three_domain_secure] || false
        }.tap do |data|
          if merchant_group_id
            data[:merchant_group_id] = merchant_group_id
          else
            data[:merchant_id] = merchant_id
          end
          data[:cardholder] = card_holder_data if options[:cardholder]
          data[:instalment] = options[:instalment] if options[:instalment]
          data[:result_url] = options[:result_url] if options[:result_url]
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
        validate_result_url! if options[:three_domain_secure]
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

      def validate_result_url!
        return if options[:result_url] && 
                 options[:result_url][:frontend_redirect_url] && 
                 options[:result_url][:backend_notify_url]

        raise ValidationError, "result_url with frontend_redirect_url and backend_notify_url is required when three_domain_secure is true"
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
