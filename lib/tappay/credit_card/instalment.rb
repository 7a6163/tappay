module Tappay
  module CreditCard
    class InstalmentBase < PayBase
      def initialize(options = {})
        super
        validate_instalment_options!
      end

      protected

      def payment_data
        super.merge(
          instalment: options[:instalment]
        )
      end

      def validate_instalment_options!
        unless options[:instalment].to_i.between?(1, 12)
          raise ValidationError, "Invalid instalment value. Must be between 1 and 12"
        end
      end
    end

    class Instalment < PayBase
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
          remember: options[:remember] || false
        )
      end

      def endpoint_url
        Tappay::Endpoints::CreditCard.instalment_url
      end

      def validate_options!
        super
        required = [:prime]
        missing = required.select { |key| options[key].nil? }
        raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
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
