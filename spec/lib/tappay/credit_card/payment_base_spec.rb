# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::CreditCard::PaymentBase do
  let(:concrete_class) do
    Class.new(described_class) do
      def endpoint_url
        'https://example.com/endpoint'
      end

      private

      def additional_required_options
        [:test_option]
      end
    end
  end

  let(:valid_options) do
    {
      amount: 100,
      details: 'Test payment',
      test_option: 'value'
    }
  end

  subject { concrete_class.new(valid_options) }

  describe '#payment_data' do
    context 'with all optional parameters' do
      let(:card_holder) { Tappay::CardHolder.new(phone_number: '0912345678', name: 'Test User', email: 'test@example.com') }
      let(:options) do
        valid_options.merge(
          merchant_id: 'custom_merchant',
          currency: 'USD',
          order_number: 'ORDER123',
          redirect_url: 'https://example.com/callback',
          three_domain_secure: true,
          cardholder: card_holder,
          instalment: 3
        )
      end

      subject { concrete_class.new(options) }

      it 'includes all parameters in the payment data' do
        data = subject.send(:payment_data)
        expect(data[:merchant_id]).to eq('custom_merchant')
        expect(data[:currency]).to eq('USD')
        expect(data[:order_number]).to eq('ORDER123')
        expect(data[:redirect_url]).to eq('https://example.com/callback')
        expect(data[:three_domain_secure]).to be true
        expect(data[:cardholder]).to eq(card_holder.to_h)
        expect(data[:instalment]).to eq(3)
      end
    end

    context 'with cardholder as a hash' do
      let(:cardholder_hash) { { phone_number: '0912345678', name: 'Test User', email: 'test@example.com' } }
      let(:options) { valid_options.merge(cardholder: cardholder_hash) }

      subject { concrete_class.new(options) }

      it 'accepts cardholder as a hash' do
        data = subject.send(:payment_data)
        expect(data[:cardholder]).to eq(cardholder_hash)
      end
    end

    context 'with invalid cardholder format' do
      let(:options) { valid_options.merge(cardholder: 'invalid') }
      subject { concrete_class.new(options) }

      it 'raises ValidationError' do
        expect { subject.send(:payment_data) }
          .to raise_error(Tappay::ValidationError, /Invalid cardholder format/)
      end
    end

    context 'with default values' do
      it 'uses configuration merchant_id' do
        Tappay.configure { |c| c.merchant_id = 'default_merchant' }
        data = subject.send(:payment_data)
        expect(data[:merchant_id]).to eq('default_merchant')
      end

      it 'uses TWD as default currency' do
        data = subject.send(:payment_data)
        expect(data[:currency]).to eq('TWD')
      end

      it 'uses false as default three_domain_secure' do
        data = subject.send(:payment_data)
        expect(data[:three_domain_secure]).to be false
      end
    end
  end

  describe '#validate_instalment!' do
    context 'with invalid instalment values' do
      [-1, 0, 13, 100].each do |value|
        it "raises ValidationError for instalment value #{value}" do
          options = valid_options.merge(instalment: value)
          expect { concrete_class.new(options) }
            .to raise_error(Tappay::ValidationError, /Invalid instalment value/)
        end
      end
    end

    context 'with valid instalment values' do
      (1..12).each do |value|
        it "accepts instalment value #{value}" do
          options = valid_options.merge(instalment: value)
          expect { concrete_class.new(options) }.not_to raise_error
        end
      end
    end
  end
end