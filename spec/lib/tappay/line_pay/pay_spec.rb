# frozen_string_literal: true

module Tappay
  module LinePay
    class Pay < PaymentBase
      def endpoint_url
        Tappay::Endpoints::Payment.pay_by_prime_url
      end

      private

      def get_merchant_id
        # If merchant_group_id is set, it takes precedence
        return nil if Tappay.configuration.merchant_group_id

        # Otherwise, use line_pay_merchant_id or fall back to default merchant_id
        Tappay.configuration.line_pay_merchant_id || super
      end

      def additional_required_options
        [:prime, :frontend_redirect_url, :backend_notify_url, :cardholder]
      end

      def validate_options!
        super
        validate_result_url_format!
      end

      def validate_result_url_format!
        result_url = {
          frontend_redirect_url: options[:frontend_redirect_url],
          backend_notify_url: options[:backend_notify_url]
        }

        if !options[:frontend_redirect_url] || !options[:backend_notify_url]
          raise ValidationError, "result_url must contain both frontend_redirect_url and backend_notify_url"
        end

        if options[:result_url]
          raise ValidationError, "result_url must be a hash" unless options[:result_url].is_a?(Hash)

          result_url = options[:result_url]
          required_fields = %w[frontend_redirect_url backend_notify_url]
          missing = required_fields.select { |field| result_url[field.to_sym].nil? && result_url[field].nil? }

          if missing.any?
            raise ValidationError, "result_url must contain both frontend_redirect_url and backend_notify_url"
          end
        end
      end

      protected

      def payment_data
        super.merge(
          prime: options[:prime],
          result_url: {
            frontend_redirect_url: options[:frontend_redirect_url],
            backend_notify_url: options[:backend_notify_url]
          }
        )
      end
    end
  end
end
