# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Transaction::Query do
  let(:order_number) { 'TEST123' }
  let(:start_time) { Time.now.to_i - 86400 }
  let(:end_time) { Time.now.to_i }
  let(:time_params) { { start_time: start_time, end_time: end_time } }
  let(:query) { described_class.new(
    time: time_params,
    order_number: order_number,
    records_per_page: 50,
    page: 0,
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

  describe '#initialize' do
    context 'with valid parameters' do
      it 'creates a new instance' do
        expect(query).to be_a(described_class)
      end
    end

    context 'with missing time parameter' do
      it 'raises ArgumentError' do
        expect {
          described_class.new(order_number: order_number)
        }.to raise_error(ArgumentError, /missing keyword: :time/)
      end
    end

    context 'with invalid time parameter' do
      it 'raises ValidationError when start_time is missing' do
        expect {
          described_class.new(time: { end_time: end_time })
        }.to raise_error(Tappay::ValidationError, /time parameter must include start_time and end_time/)
      end

      it 'raises ValidationError when end_time is missing' do
        expect {
          described_class.new(time: { start_time: start_time })
        }.to raise_error(Tappay::ValidationError, /time parameter must include start_time and end_time/)
      end

      it 'raises ValidationError when timestamps are not integers' do
        expect {
          described_class.new(time: { start_time: 'invalid', end_time: 'invalid' })
        }.to raise_error(Tappay::ValidationError, /start_time and end_time must be Unix timestamps/)
      end

      it 'raises ValidationError when start_time is later than end_time' do
        expect {
          described_class.new(time: { start_time: end_time + 1, end_time: end_time })
        }.to raise_error(Tappay::ValidationError, /start_time cannot be later than end_time/)
      end
    end
  end

  describe '#execute' do
    context 'when the response contains trade records' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
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
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
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
        expect(result[:records_per_page]).to eq(50)
        expect(result[:page]).to eq(0)
        expect(result[:total_page_count]).to eq(1)
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
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 0,
          'trade_records' => []
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
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
        expect(result[:records_per_page]).to eq(50)
        expect(result[:page]).to eq(0)
        expect(result[:total_page_count]).to eq(1)
        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    context 'when trade_records is nil' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 0,
          'trade_records' => nil
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
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
        expect(result[:records_per_page]).to eq(50)
        expect(result[:page]).to eq(0)
        expect(result[:total_page_count]).to eq(1)
        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    context 'when cardholder is nil' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD',
              'order_number' => order_number,
              'cardholder' => nil
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
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
    context 'without order_number' do
      let(:simple_query) { described_class.new(time: time_params) }
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD'
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              time: time_params
            }
          }
        ).and_return(response)
      end

      it 'sends request without order_number parameter' do
        result = simple_query.execute
        expect(result[:status]).to eq(0)
        expect(result[:trade_records].first[:amount]).to eq(1000)
      end
    end
  end
end
