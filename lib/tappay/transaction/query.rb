# frozen_string_literal: true

module Tappay
  module Transaction
    class Query
      def initialize(time:, order_number: nil, records_per_page: 50, page: 0, order_by: nil)
        @time = validate_time!(time)
        @order_number = order_number
        @records_per_page = records_per_page
        @page = page
        @order_by = order_by
      end

      def execute
        client = Tappay::Client.new
        response = client.post(Endpoints::Transaction.query_url, request_params)

        {
          status: response['status'],
          msg: response['msg'],
          records_per_page: response['records_per_page'],
          page: response['page'],
          total_page_count: response['total_page_count'],
          number_of_transactions: response['number_of_transactions'],
          trade_records: parse_trade_records(response['trade_records'])
        }
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
          time: @time
        }.compact
      end

      def validate_time!(time)
        unless time.is_a?(Hash) && time[:start_time] && time[:end_time]
          raise Tappay::ValidationError, "time parameter must include start_time and end_time"
        end

        unless time[:start_time].is_a?(Integer) && time[:end_time].is_a?(Integer)
          raise Tappay::ValidationError, "start_time and end_time must be Unix timestamps (integers)"
        end

        if time[:start_time] > time[:end_time]
          raise Tappay::ValidationError, "start_time cannot be later than end_time"
        end

        time
      end

      def parse_trade_records(records)
        return [] unless records&.any?

        records.map do |record|
          {
            record_status: record['record_status'],
            rec_trade_id: record['rec_trade_id'],
            amount: record['amount'],
            currency: record['currency'],
            order_number: record['order_number'],
            bank_transaction_id: record['bank_transaction_id'],
            auth_code: record['auth_code'],
            cardholder: parse_cardholder(record['cardholder']),
            merchant_id: record['merchant_id'],
            transaction_time: record['transaction_time'],
            tsp: record['tsp'],
            card_identifier: record['card_identifier']
          }
        end
      end

      def parse_cardholder(cardholder)
        return unless cardholder

        {
          phone_number: cardholder['phone_number'],
          name: cardholder['name'],
          email: cardholder['email']
        }
      end
    end
  end
end
