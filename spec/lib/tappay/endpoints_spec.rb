# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Endpoints do
  describe '.base_url' do
    context 'when in sandbox mode' do
      before do
        allow(Tappay.configuration).to receive(:sandbox?).and_return(true)
      end

      it 'returns sandbox URL' do
        expect(described_class.base_url).to eq('https://sandbox.tappaysdk.com')
      end
    end

    context 'when in production mode' do
      before do
        allow(Tappay.configuration).to receive(:sandbox?).and_return(false)
      end

      it 'returns production URL' do
        expect(described_class.base_url).to eq('https://prod.tappaysdk.com')
      end
    end
  end

  describe Tappay::Endpoints::Payment do
    let(:base_url) { 'https://sandbox.tappaysdk.com' }

    before do
      allow(Tappay::Endpoints).to receive(:base_url).and_return(base_url)
    end

    describe '.pay_by_prime_url' do
      it 'returns correct URL' do
        expect(described_class.pay_by_prime_url).to eq("#{base_url}/tpc/payment/pay-by-prime")
      end
    end

    describe '.pay_by_token_url' do
      it 'returns correct URL' do
        expect(described_class.pay_by_token_url).to eq("#{base_url}/tpc/payment/pay-by-token")
      end
    end
  end

  describe Tappay::Endpoints::CreditCard do
    let(:base_url) { 'https://sandbox.tappaysdk.com' }

    before do
      allow(Tappay::Endpoints).to receive(:base_url).and_return(base_url)
    end

    describe '.refund_url' do
      it 'returns correct URL' do
        expect(described_class.refund_url).to eq("#{base_url}/tpc/transaction/refund")
      end
    end
  end

  describe Tappay::Endpoints::Transaction do
    let(:base_url) { 'https://sandbox.tappaysdk.com' }

    before do
      allow(Tappay::Endpoints).to receive(:base_url).and_return(base_url)
    end

    describe '.query_url' do
      it 'returns correct URL' do
        expect(described_class.query_url).to eq("#{base_url}/tpc/transaction/query")
      end
    end

    describe '.trade_history_url' do
      it 'returns correct URL' do
        expect(described_class.trade_history_url).to eq("#{base_url}/tpc/transaction/trade-history")
      end
    end

    describe '.cap_url' do
      it 'returns correct URL' do
        expect(described_class.cap_url).to eq("#{base_url}/tpc/transaction/cap")
      end
    end
  end

  describe Tappay::Endpoints::Bind do
    let(:base_url) { 'https://sandbox.tappaysdk.com' }

    before do
      allow(Tappay::Endpoints).to receive(:base_url).and_return(base_url)
    end

    describe '.bind_card_url' do
      it 'returns correct URL' do
        expect(described_class.bind_card_url).to eq("#{base_url}/tpc/card/bind")
      end
    end

    describe '.remove_card_url' do
      it 'returns correct URL' do
        expect(described_class.remove_card_url).to eq("#{base_url}/tpc/card/remove")
      end
    end
  end

  describe Tappay::Endpoints::LinePay do
    let(:base_url) { 'https://sandbox.tappaysdk.com' }

    before do
      allow(Tappay::Endpoints).to receive(:base_url).and_return(base_url)
    end

    describe '.redirect_url' do
      it 'returns correct URL' do
        expect(described_class.redirect_url).to eq("#{base_url}/tpc/payment/redirect")
      end
    end
  end
end
