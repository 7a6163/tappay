# frozen_string_literal: true

module Tappay
  module Transaction
    class Query
      def initialize(order_number:)
        @order_number = order_number
      end

      def execute
        client = Tappay::Client.new
        response = client.post('/tpc/transaction/query', request_params)
        
        {
          number_of_transactions: response['number_of_transactions'],
          trade_records: parse_trade_records(response['trade_records'])
        }
      end

      private

      def request_params
        {
          filters: {
            order_number: @order_number
          }
        }
      end

      def parse_trade_records(records)
        return [] unless records&.any?

        records.map do |record|
          {
            record_status: record['record_status'],
            rec_trade_id: record['rec_trade_id'],
            amount: record['amount'],
            status: record['status'],
            order_number: record['order_number'],
            acquirer: record['acquirer'],
            transaction_time: record['transaction_time'],
            bank_transaction_id: record['bank_transaction_id']
          }
        end
      end
    end
  end
end
