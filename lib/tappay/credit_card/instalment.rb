module Tappay
  module CreditCard
    class Instalment < Pay
      def initialize(options = {})
        super
        validate_instalment_options!
      end

      private

      def payment_data
        super.merge(
          instalment: options[:instalment],
          merchant_id: options[:merchant_id] || Tappay.configuration.instalment_merchant_id
        )
      end

      def validate_instalment_options!
        unless options[:instalment].to_i.between?(1, 12)
          raise ValidationError, "Invalid instalment value. Must be between 1 and 12"
        end
      end
    end
  end
end
