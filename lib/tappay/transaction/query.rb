# frozen_string_literal: true

module Tappay
  module Transaction
    class Query
      # TapPay's time filter is in milliseconds. Values at the wrong scale are
      # accepted by the API but match nothing (seconds land in 1970,
      # microseconds in the year 50000), so reject them loudly rather than
      # returning an empty list.
      # ponytail: magnitude heuristic, only valid for 1973-03-03 .. 5138-11-16
      MILLIS_FLOOR = 100_000_000_000
      MILLIS_CEILING = 100_000_000_000_000

      def initialize(time:, order_number: nil, bank_transaction_id: nil, records_per_page: 50, page: 0, order_by: nil)
        @time = validate_time!(time)
        @order_number = order_number
        @bank_transaction_id = bank_transaction_id
        @records_per_page = records_per_page
        @page = page
        @order_by = order_by
      end

      def execute
        client = Tappay::Client.new
        response = client.post(Endpoints::Transaction.query_url, request_params)

        result = symbolize_keys(response.parsed_response)
        result[:trade_records] ||= []
        result
      end

      private

      def request_params
        {
          partner_key: Tappay.configuration.partner_key,
          records_per_page: @records_per_page,
          page: @page,
          filters: filters,
          order_by: @order_by
        }.compact
      end

      def filters
        {
          order_number: @order_number,
          bank_transaction_id: @bank_transaction_id,
          time: @time
        }.compact
      end

      def validate_time!(time)
        unless time.is_a?(Hash) && time[:start_time] && time[:end_time]
          raise Tappay::ValidationError, "time parameter must include start_time and end_time"
        end

        unless time[:start_time].is_a?(Integer) && time[:end_time].is_a?(Integer)
          raise Tappay::ValidationError, "start_time and end_time must be Unix timestamps in milliseconds (integers)"
        end

        if time[:start_time] < MILLIS_FLOOR || time[:end_time] < MILLIS_FLOOR
          raise Tappay::ValidationError,
                "start_time and end_time must be in milliseconds, not seconds (multiply by 1000)"
        end

        if time[:start_time] >= MILLIS_CEILING || time[:end_time] >= MILLIS_CEILING
          raise Tappay::ValidationError,
                "start_time and end_time are too large to be milliseconds (microseconds?)"
        end

        if time[:start_time] > time[:end_time]
          raise Tappay::ValidationError, "start_time cannot be later than end_time"
        end

        time
      end

      # Pass every field TapPay returns straight through, at the envelope level
      # as well as per trade record. A whitelist silently drops new fields and
      # silently returns nil for a mistyped key.
      def symbolize_keys(value)
        case value
        when Hash then value.to_h { |k, v| [k.to_sym, symbolize_keys(v)] }
        when Array then value.map { |v| symbolize_keys(v) }
        else value
        end
      end
    end
  end
end
