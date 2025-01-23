module Tappay
  class Refund < Client
    def initialize(options = {})
      super
      validate_options!
    end

    def execute
      post(Endpoints.refund_url, refund_data)
    end

    private

    def refund_data
      data = {
        partner_key: Tappay.configuration.partner_key,
        rec_trade_id: options[:rec_trade_id]
      }

      data[:amount] = options[:amount] if options[:amount]
      data
    end

    def validate_options!
      required = [:rec_trade_id]
      missing = required.select { |key| options[key].nil? }
      raise ValidationError, "Missing required options: #{missing.join(', ')}" if missing.any?
    end
  end
end
