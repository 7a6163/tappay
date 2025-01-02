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
        Tappay::Endpoints::Payment.pay_by_prime_url
      end

      def validate_options!
        super
        validate_result_url_for_instalment!
      end

      private

      def get_merchant_id
        Tappay.configuration.instalment_merchant_id || super
      end

      def additional_required_options
        [:prime, :cardholder, :instalment]
      end

      def validate_result_url_for_instalment!
        return if options[:result_url] && 
                 options[:result_url][:frontend_redirect_url] && 
                 options[:result_url][:backend_notify_url]

        raise ValidationError, "result_url with frontend_redirect_url and backend_notify_url is required for instalment payments"
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
        Tappay::Endpoints::Payment.pay_by_token_url
      end

      def validate_options!
        super
        validate_result_url_for_instalment!
      end

      private

      def get_merchant_id
        Tappay.configuration.instalment_merchant_id || super
      end

      def additional_required_options
        [:card_key, :card_token, :instalment]
      end

      def validate_result_url_for_instalment!
        return if options[:result_url] && 
                 options[:result_url][:frontend_redirect_url] && 
                 options[:result_url][:backend_notify_url]

        raise ValidationError, "result_url with frontend_redirect_url and backend_notify_url is required for instalment payments"
      end
    end
  end
end
