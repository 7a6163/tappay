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

  describe '#endpoint_url' do
    let(:base_class) { Class.new(described_class) }
    subject { base_class.new(valid_options) }

    it 'raises NotImplementedError' do
      expect { subject.send(:endpoint_url) }
        .to raise_error(NotImplementedError, "Subclass must implement abstract method 'endpoint_url'")
    end
  end

  describe '#additional_required_options' do
    let(:base_class) { Class.new(described_class) }
    subject { base_class.new(valid_options) }

    it 'returns an empty array by default' do
      expect(subject.send(:additional_required_options)).to eq([])
    end
  end

  describe '#card_holder_data' do
    context 'when cardholder is nil' do
      let(:options) { valid_options.tap { |o| o.delete(:cardholder) } }
      subject { concrete_class.new(options) }

      it 'returns nil' do
        expect(subject.send(:card_holder_data)).to be_nil
      end
    end

    context 'when cardholder is a CardHolder instance' do
      let(:card_holder) { Tappay::CardHolder.new(phone_number: '0912345678', name: 'Test User', email: 'test@example.com') }
      let(:options) { valid_options.merge(cardholder: card_holder) }
      subject { concrete_class.new(options) }

      it 'returns cardholder hash' do
        expect(subject.send(:card_holder_data)).to eq(card_holder.to_h)
      end
    end

    context 'when cardholder is a Hash' do
      let(:cardholder_hash) { { phone_number: '0912345678', name: 'Test User', email: 'test@example.com' } }
      let(:options) { valid_options.merge(cardholder: cardholder_hash) }
      subject { concrete_class.new(options) }

      it 'returns the hash directly' do
        expect(subject.send(:card_holder_data)).to eq(cardholder_hash)
      end
    end

    context 'when cardholder is invalid' do
      let(:options) { valid_options.merge(cardholder: 'invalid') }
      subject { concrete_class.new(options) }

      it 'raises ValidationError' do
        expect { subject.send(:card_holder_data) }
          .to raise_error(Tappay::ValidationError, /Invalid cardholder format/)
      end
    end
  end

  describe '#payment_data' do
    context 'with all optional parameters' do
      let(:card_holder) { Tappay::CardHolder.new(phone_number: '0912345678', name: 'Test User', email: 'test@example.com') }
      let(:options) do
        valid_options.merge(
          merchant_id: 'custom_merchant',
          currency: 'TWD',
          order_number: 'ORDER123',
          three_domain_secure: true,
          cardholder: card_holder,
          instalment: 3
        )
      end

      subject { concrete_class.new(options) }

      it 'includes all parameters in the payment data' do
        Tappay.configure { |c| c.merchant_group_id = nil }
        data = subject.send(:payment_data)
        expect(data[:merchant_id]).to eq('custom_merchant')
        expect(data[:currency]).to eq('TWD')
        expect(data[:order_number]).to eq('ORDER123')
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

    context 'without cardholder' do
      let(:options) { valid_options.tap { |o| o.delete(:cardholder) } }
      subject { concrete_class.new(options) }

      it 'excludes cardholder from payment data' do
        data = subject.send(:payment_data)
        expect(data).not_to have_key(:cardholder)
      end
    end

    context 'with merchant_group_id' do
      let(:options) { valid_options.merge(merchant_group_id: 'group_123') }

      before do
        Tappay.configure { |c| c.merchant_id = nil }
      end

      subject { concrete_class.new(options) }

      it 'includes merchant_group_id and excludes merchant_id' do
        data = subject.send(:payment_data)
        expect(data[:merchant_group_id]).to eq('group_123')
        expect(data).not_to have_key(:merchant_id)
      end

      it 'raises error when both merchant_group_id and merchant_id are set' do
        options[:merchant_id] = 'merchant_123'
        expect { subject.send(:payment_data) }
          .to raise_error(Tappay::ValidationError, /cannot be used together/)
      end

      it 'raises error when both are set in configuration' do
        Tappay.configure do |c|
          c.merchant_group_id = 'group_123'
          c.merchant_id = 'merchant_123'
        end
        expect { subject.send(:payment_data) }
          .to raise_error(Tappay::ValidationError, /cannot be used together/)
      end
    end

    context 'with merchant ID validation' do
      before do
        Tappay.configure do |c|
          c.merchant_id = nil
          c.merchant_group_id = nil
        end
      end

      it 'raises error when neither merchant_id nor merchant_group_id is provided' do
        expect { subject.send(:payment_data) }
          .to raise_error(Tappay::ValidationError, /Either merchant_group_id or merchant_id must be provided/)
      end

      it 'raises error when both merchant_id and merchant_group_id are provided in options' do
        options = valid_options.merge(
          merchant_id: 'merchant_123',
          merchant_group_id: 'group_123'
        )
        subject = concrete_class.new(options)
        expect { subject.send(:payment_data) }
          .to raise_error(Tappay::ValidationError, /cannot be used together/)
      end

      it 'ignores configuration when options are provided' do
        Tappay.configure { |c| c.merchant_id = 'merchant_123' }
        options = valid_options.merge(merchant_group_id: 'group_123')
        subject = concrete_class.new(options)
        data = subject.send(:payment_data)
        expect(data[:merchant_group_id]).to eq('group_123')
        expect(data).not_to have_key(:merchant_id)
      end

      it 'prefers merchant_group_id from options over configuration' do
        Tappay.configure do |c|
          c.merchant_group_id = 'group_456'
        end
        options = valid_options.merge(merchant_group_id: 'group_123')
        subject = concrete_class.new(options)
        data = subject.send(:payment_data)
        expect(data[:merchant_group_id]).to eq('group_123')
        expect(data).not_to have_key(:merchant_id)
      end

      it 'ignores configuration when options are provided' do
        Tappay.configure { |c| c.merchant_id = 'merchant_123' }
        options = valid_options.merge(merchant_group_id: 'group_123')
        subject = concrete_class.new(options)
        data = subject.send(:payment_data)
        expect(data[:merchant_group_id]).to eq('group_123')
        expect(data).not_to have_key(:merchant_id)
      end
    end

    context 'with default values' do
      before do
        Tappay.configure do |c|
          c.merchant_group_id = nil
          c.merchant_id = 'default_merchant'
        end
      end

      it 'uses configuration merchant_id' do
        data = subject.send(:payment_data)
        expect(data[:merchant_id]).to eq('default_merchant')
      end

      it 'uses configuration merchant_group_id when available' do
        Tappay.configure do |c|
          c.merchant_id = nil
          c.merchant_group_id = 'default_group'
        end
        data = subject.send(:payment_data)
        expect(data[:merchant_group_id]).to eq('default_group')
        expect(data).not_to have_key(:merchant_id)
      end

      it 'excludes merchant_group_id when not set' do
        data = subject.send(:payment_data)
        expect(data).not_to have_key(:merchant_group_id)
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
