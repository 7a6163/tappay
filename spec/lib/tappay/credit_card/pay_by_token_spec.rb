# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::CreditCard::PayByToken do
  let(:valid_options) do
    {
      amount: 100,
      details: 'Test payment',
      card_key: 'test_card_key',
      card_token: 'test_card_token',
      currency: 'TWD'
    }
  end

  subject { described_class.new(valid_options) }

  describe '#payment_data' do
    it 'includes card_key and card_token in payment data' do
      data = subject.send(:payment_data)
      expect(data[:card_key]).to eq('test_card_key')
      expect(data[:card_token]).to eq('test_card_token')
    end

    it 'includes base payment data' do
      data = subject.send(:payment_data)
      expect(data[:amount]).to eq(100)
      expect(data[:details]).to eq('Test payment')
    end
  end

  describe '#endpoint_url' do
    it 'returns the correct endpoint URL' do
      expect(subject.send(:endpoint_url))
        .to eq(Tappay::Endpoints::Payment.pay_by_token_url)
    end
  end

  describe 'validation' do
    context 'with missing card_key' do
      let(:options) { valid_options.tap { |o| o.delete(:card_key) } }

      it 'raises ValidationError' do
        expect { described_class.new(options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: card_key/)
      end
    end

    context 'with missing card_token' do
      let(:options) { valid_options.tap { |o| o.delete(:card_token) } }

      it 'raises ValidationError' do
        expect { described_class.new(options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: card_token/)
      end
    end

    context 'with missing currency' do
      let(:options) { valid_options.tap { |o| o.delete(:currency) } }

      it 'raises ValidationError' do
        expect { described_class.new(options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: currency/)
      end
    end
  end
end
