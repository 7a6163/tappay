# frozen_string_literal: true

module Tappay
  class Configuration
    attr_accessor :partner_key, :merchant_id, :merchant_group_id, :instalment_merchant_id,
                 :line_pay_merchant_id, :jko_pay_merchant_id, :app_id, :currency, :vat_number,
                 :google_pay_merchant_id, :apple_pay_merchant_id
    attr_writer :api_version

    def initialize
      @mode = :sandbox
      @api_version = '3'
    end

    def api_version
      @api_version.to_s
    end

    def sandbox?
      @mode == :sandbox
    end

    def production?
      @mode == :production
    end

    def mode=(value)
      unless [:sandbox, :production].include?(value.to_sym)
        raise ArgumentError, "Invalid mode. Must be :sandbox or :production"
      end
      @mode = value.to_sym
    end

    def mode
      @mode ||= :sandbox
    end

    def validate!
      raise ValidationError, 'partner_key is required' if partner_key.nil?
      raise ValidationError, 'Either merchant_id or merchant_group_id is required' if merchant_id.nil? && merchant_group_id.nil?
    end
  end
end
