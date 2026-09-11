# frozen_string_literal: true

module Tappay
  class PaymentBase < Client
    VALID_INSTALMENT_VALUES = [0, 3, 6, 12, 18, 24, 30].freeze

    class << self
      # Some payment methods get their own merchant ID from TapPay. Declaring
      # the config key here replaces a get_merchant_id override per class.
      def uses_merchant_id(key)
        @merchant_id_key = key
      end

      # Walks the ancestry, because a class-level ivar is not inherited and
      # the get_merchant_id overrides this replaced were. Without this, a
      # subclass of a payment class silently charges the default merchant.
      def merchant_id_key
        @merchant_id_key ||
          (superclass.merchant_id_key if superclass.respond_to?(:merchant_id_key))
      end
    end

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
        currency: options[:currency] || Tappay.configuration.currency || 'TWD',
        order_number: options[:order_number],
        three_domain_secure: options[:three_domain_secure] || false
      }).tap do |data|
        data[:cardholder] = card_holder_data if options[:cardholder]
        data[:result_url] = options[:result_url] if options[:result_url]
        data[:instalment] = options[:instalment] || 0
        data[:bank_transaction_id] = options[:bank_transaction_id] if options[:bank_transaction_id]
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
      # merchant_group_id takes precedence over every merchant ID.
      return nil if Tappay.configuration.merchant_group_id

      key = self.class.merchant_id_key
      (key && Tappay.configuration.public_send(key)) || Tappay.configuration.merchant_id
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
      validate_result_url_hash!(options[:result_url])
    end

    # The one definition of what a result_url hash has to look like. Both the
    # 3DS path above and the redirect payment methods check against this.
    def validate_result_url_hash!(result_url)
      raise ValidationError, "result_url must be a hash" unless result_url.is_a?(Hash)

      required_fields = %w[frontend_redirect_url backend_notify_url]
      missing = required_fields.select { |field| result_url[field.to_sym].nil? && result_url[field].nil? }

      if missing.any?
        raise ValidationError, "result_url must contain both frontend_redirect_url and backend_notify_url"
      end
    end
  end
end
