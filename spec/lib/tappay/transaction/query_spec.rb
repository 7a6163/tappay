# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Transaction::Query do
  let(:order_number) { 'TEST123' }
  let(:query) { described_class.new(order_number: order_number) }
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
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'status' => 0,
              'order_number' => order_number,
              'acquirer' => 'NCCC',
              'transaction_time' => '2024-12-23 13:50:33',
              'bank_transaction_id' => 'BANK123'
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          { filters: { order_number: order_number } }
        ).and_return(response)
      end

      it 'returns parsed transaction data' do
        result = query.execute

        expect(result[:number_of_transactions]).to eq(1)
        expect(result[:trade_records]).to be_an(Array)
        expect(result[:trade_records].first).to include(
          record_status: 0,
          rec_trade_id: 'RECTRADE123',
          amount: 1000,
          status: 0,
          order_number: order_number,
          acquirer: 'NCCC',
          transaction_time: '2024-12-23 13:50:33',
          bank_transaction_id: 'BANK123'
        )
      end
    end

    context 'when the response contains no trade records' do
      let(:response) do
        {
          'number_of_transactions' => 0,
          'trade_records' => []
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          { filters: { order_number: order_number } }
        ).and_return(response)
      end

      it 'returns empty trade records' do
        result = query.execute

        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    context 'when trade_records is nil' do
      let(:response) do
        {
          'number_of_transactions' => 0,
          'trade_records' => nil
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          { filters: { order_number: order_number } }
        ).and_return(response)
      end

      it 'returns empty trade records' do
        result = query.execute

        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end
  end
end
