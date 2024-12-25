# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Transaction::Query do
  let(:order_number) { 'TEST123' }
  let(:start_time) { Time.now.to_i - 86400 }
  let(:end_time) { Time.now.to_i }
  let(:query) { described_class.new(
    order_number: order_number,
    records_per_page: 50,
    page: 0,
    time: {
      start_time: start_time,
      end_time: end_time
    },
    order_by: {
      attribute: 'time',
      is_descending: true
    }
  ) }
  let(:client) { instance_double(Tappay::Client) }
  let(:query_url) { 'https://sandbox.tappaysdk.com/tpc/transaction/query' }

  before do
    allow(Tappay::Client).to receive(:new).and_return(client)
    allow(Tappay::Endpoints::Transaction).to receive(:query_url).and_return(query_url)
  end

  describe '#execute' do
    context 'when the response contains trade records' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD',
              'order_number' => order_number,
              'bank_transaction_id' => 'BANK123',
              'auth_code' => 'AUTH123',
              'cardholder' => {
                'phone_number' => '0912345678',
                'name' => 'Test User',
                'email' => 'test@example.com'
              },
              'merchant_id' => 'MERCHANT123',
              'transaction_time' => '2024-12-23 13:50:33',
              'tsp' => true,
              'card_identifier' => 'CARD123'
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: {
                start_time: start_time,
                end_time: end_time
              }
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(response)
      end

      it 'returns parsed transaction data' do
        result = query.execute

        expect(result[:status]).to eq(0)
        expect(result[:msg]).to eq('Success')
        expect(result[:number_of_transactions]).to eq(1)
        expect(result[:trade_records]).to be_an(Array)
        expect(result[:trade_records].first).to include(
          record_status: 0,
          rec_trade_id: 'RECTRADE123',
          amount: 1000,
          currency: 'TWD',
          order_number: order_number,
          bank_transaction_id: 'BANK123',
          auth_code: 'AUTH123',
          merchant_id: 'MERCHANT123',
          transaction_time: '2024-12-23 13:50:33',
          tsp: true,
          card_identifier: 'CARD123'
        )
        expect(result[:trade_records].first[:cardholder]).to include(
          phone_number: '0912345678',
          name: 'Test User',
          email: 'test@example.com'
        )
      end
    end

    context 'when the response contains no trade records' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'number_of_transactions' => 0,
          'trade_records' => []
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: {
                start_time: start_time,
                end_time: end_time
              }
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(response)
      end

      it 'returns empty trade records' do
        result = query.execute

        expect(result[:status]).to eq(0)
        expect(result[:msg]).to eq('Success')
        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    context 'when trade_records is nil' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'number_of_transactions' => 0,
          'trade_records' => nil
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: {
                start_time: start_time,
                end_time: end_time
              }
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(response)
      end

      it 'returns empty trade records' do
        result = query.execute

        expect(result[:status]).to eq(0)
        expect(result[:msg]).to eq('Success')
        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    context 'when cardholder is nil' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD',
              'order_number' => order_number,
              'bank_transaction_id' => 'BANK123',
              'auth_code' => 'AUTH123',
              'cardholder' => nil,
              'merchant_id' => 'MERCHANT123',
              'transaction_time' => '2024-12-23 13:50:33',
              'tsp' => true,
              'card_identifier' => 'CARD123'
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: {
                start_time: start_time,
                end_time: end_time
              }
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(response)
      end

      it 'returns nil for cardholder' do
        result = query.execute
        expect(result[:trade_records].first[:cardholder]).to be_nil
      end
    end
  end

  describe 'optional parameters' do
    context 'without time and order_by' do
      let(:simple_query) { described_class.new(order_number: order_number) }
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD',
              'order_number' => order_number
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number
            }
          }
        ).and_return(response)
      end

      it 'sends request without time and order_by parameters' do
        result = simple_query.execute
        expect(result[:status]).to eq(0)
        expect(result[:trade_records].first[:order_number]).to eq(order_number)
      end
    end
  end
end
