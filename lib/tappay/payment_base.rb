# frozen_string_literal: true

module Tappay
  class PaymentBase < Client
    VALID_INSTALMENT_VALUES = [0, 3, 6, 12, 24, 30].freeze

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
      # Prioritize merchant_group_id from options, then configuration
      merchant_group_id = options[:merchant_group_id] || Tappay.configuration.merchant_group_id
      merchant_id = options[:merchant_id] || get_merchant_id
      
      # Determine which identifier to use
      identifier = if merchant_group_id
        { merchant_group_id: merchant_group_id }
      else
        raise Tappay::ValidationError, "Either merchant_group_id or merchant_id must be provided" unless merchant_id
        { merchant_id: merchant_id }
      end

      identifier.merge({
        partner_key: Tappay.configuration.partner_key,
        amount: options[:amount],
        details: options[:details],
        currency: options[:currency] || 'TWD',
        order_number: options[:order_number],
        three_domain_secure: options[:three_domain_secure] || false
      }).tap do |data|
        data[:cardholder] = card_holder_data if options[:cardholder]
        data[:result_url] = options[:result_url] if options[:result_url]
        data[:instalment] = options[:instalment] || 0
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

      validate_amount!
      validate_instalment! if options[:instalment]
      validate_result_url! if options[:three_domain_secure]
    end

    private

    def validate_amount!
      amount = options[:amount]
      if !amount.is_a?(Numeric)
        raise ValidationError, "amount must be a number"
      elsif amount <= 0
        raise ValidationError, "amount must be greater than 0"
      end
    end

    def get_merchant_id
      Tappay.configuration.merchant_id
    end

    def base_required_options
      [:amount, :details]
    end

    def additional_required_options
      []
    end

    def validate_instalment!
      instalment = options[:instalment].to_i
      unless VALID_INSTALMENT_VALUES.include?(instalment)
        raise ValidationError, "Instalment must be one of: #{VALID_INSTALMENT_VALUES.join(', ')}"
      end
    end

    def validate_result_url!
      result_url = options[:result_url]
      raise ValidationError, "result_url must be a hash" unless result_url.is_a?(Hash)

      required_fields = %w[frontend_redirect_url backend_notify_url]
      missing = required_fields.select { |field| result_url[field.to_sym].nil? && result_url[field].nil? }

      if missing.any?
        raise ValidationError, "result_url must contain both frontend_redirect_url and backend_notify_url"
      end
    end
  end
end
