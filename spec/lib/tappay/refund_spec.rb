# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Refund do
  let(:rec_trade_id) { 'TEST_TRANSACTION_123' }
  let(:amount) { 1000 }
  let(:refund_url) { 'https://sandbox.tappaysdk.com/tpc/transaction/refund' }

  before do
    allow(Tappay::Endpoints).to receive(:refund_url).and_return(refund_url)
  end

  describe '#initialize' do
    context 'with valid options' do
      context 'with amount' do
        let(:refund) do
          described_class.new(
            rec_trade_id: rec_trade_id,
            amount: amount
          )
        end

        it 'creates a new instance' do
          expect(refund).to be_a(described_class)
        end
      end

      context 'without amount' do
        let(:refund) do
          described_class.new(rec_trade_id: rec_trade_id)
        end

        it 'creates a new instance' do
          expect(refund).to be_a(described_class)
        end
      end
    end

    context 'with missing rec_trade_id' do
      it 'raises ValidationError' do
        expect {
          described_class.new(amount: amount)
        }.to raise_error(Tappay::ValidationError, /Missing required options: rec_trade_id/)
      end
    end

    context 'with missing all required options' do
      it 'raises ValidationError' do
        expect {
          described_class.new({})
        }.to raise_error(Tappay::ValidationError, /Missing required options: rec_trade_id/)
      end
    end
  end

  describe '#execute' do
    let(:response) { double('response') }

    context 'with amount' do
      let(:refund) do
        described_class.new(
          rec_trade_id: rec_trade_id,
          amount: amount
        )
      end

      before do
        allow(refund).to receive(:post).and_return(response)
      end

      it 'calls post with amount parameter' do
        expect(refund).to receive(:post).with(
          refund_url,
          {
            partner_key: Tappay.configuration.partner_key,
            rec_trade_id: rec_trade_id,
            amount: amount
          }
        )

        refund.execute
      end

      it 'returns response' do
        expect(refund.execute).to eq(response)
      end
    end

    context 'without amount' do
      let(:refund) do
        described_class.new(rec_trade_id: rec_trade_id)
      end

      before do
        allow(refund).to receive(:post).and_return(response)
      end

      it 'calls post without amount parameter' do
        expect(refund).to receive(:post).with(
          refund_url,
          {
            partner_key: Tappay.configuration.partner_key,
            rec_trade_id: rec_trade_id
          }
        )

        refund.execute
      end

      it 'returns response' do
        expect(refund.execute).to eq(response)
      end
    end
  end
end
