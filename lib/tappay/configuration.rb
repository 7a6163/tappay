module Tappay
  class Configuration
    attr_accessor :partner_key, :merchant_id, :instalment_merchant_id, :app_id, :currency, :vat_number
    attr_writer :api_version

    def initialize
      @mode = :sandbox
      @api_version = '2'
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
  end
end
