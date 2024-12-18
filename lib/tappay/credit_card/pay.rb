module Tappay
  module CreditCard
    class Pay < Client
      def initialize(options = {})
        super
        validate_options!
      end

      def execute
        url = options[:token] ? Tappay.configuration.token_url : Tappay.configuration.prime_url
        post(url, payment_data)
      end

      private

      def payment_data
        {
          partner_key: Tappay.configuration.partner_key,
          merchant_id: Tappay.configuration.merchant_id,
          amount: options[:amount],
          currency: options[:currency] || 'TWD',
          details: options[:details],
          cardholder: options[:cardholder],
          remember: options[:remember] || false
        }.tap do |data|
          if options[:token]
            data[:card_key] = options[:token]
            data[:card_token] = options[:card_token]
          else
            data[:prime] = options[:prime]
          end
        end
      end

      def validate_options!
        required = options[:token] ? [:token, :card_token, :amount] : [:prime, :amount]
        missing = required.select { |key| options[key].nil? }
        
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end
    end
  end
end
