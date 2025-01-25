# frozen_string_literal: true

module Tappay
  module Transaction
    class Query
      def initialize(order_number:, records_per_page: 50, page: 0, time: nil, order_by: nil)
        @order_number = order_number
        @records_per_page = records_per_page
        @page = page
        @time = time
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
