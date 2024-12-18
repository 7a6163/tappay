module Tappay
  module CreditCard
    class Refund < Client
      def initialize(options = {})
        super
        validate_options!
      end

      def execute
        post(Tappay.configuration.refund_url, refund_data)
      end

      private

      def refund_data
        {
          partner_key: Tappay.configuration.partner_key,
          rec_trade_id: options[:transaction_id],
          amount: options[:amount]
        }
      end

      def validate_options!
        required = [:transaction_id, :amount]
        missing = required.select { |key| options[key].nil? }
        
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
      end
    end
  end
end
