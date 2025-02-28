# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::PaymentBase do
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
    before do
      Tappay.configure do |config|
        config.partner_key = 'test_partner_key'
        config.merchant_id = 'test_merchant_id'
      end
    end

    context 'with all optional parameters' do
      let(:card_holder) { Tappay::CardHolder.new(phone_number: '0912345678', name: 'Test User', email: 'test@example.com') }
      let(:result_url) do
        {
          frontend_redirect_url: 'https://example.com/redirect',
          backend_notify_url: 'https://example.com/notify',
          go_back_url: 'https://example.com/back'
        }
      end
      let(:options) do
        valid_options.merge(
          merchant_id: 'custom_merchant',
          currency: 'TWD',
          order_number: 'ORDER123',
          three_domain_secure: true,
          cardholder: card_holder,
          instalment: 3,
          result_url: result_url
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
        expect(data[:result_url]).to eq(result_url)
      end
    end

    context 'with default values' do
      subject { concrete_class.new(valid_options) }

      before do
        Tappay.configure do |c|
          c.merchant_id = 'default_merchant'
          c.merchant_group_id = nil
        end
      end

      it 'uses default values' do
        data = subject.send(:payment_data)
        expect(data[:currency]).to eq('TWD')
        expect(data[:three_domain_secure]).to be false
        expect(data[:instalment]).to eq(0)
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
      subject { concrete_class.new(options) }

      it 'uses merchant_group_id from options' do
        expect(subject.send(:payment_data)[:merchant_group_id]).to eq('group_123')
        expect(subject.send(:payment_data)[:merchant_id]).to be_nil
      end

      context 'when also configured in Tappay.configuration' do
        before do
          Tappay.configuration.merchant_group_id = 'config_group_123'
        end

        it 'prefers merchant_group_id from options' do
          expect(subject.send(:payment_data)[:merchant_group_id]).to eq('group_123')
          expect(subject.send(:payment_data)[:merchant_id]).to be_nil
        end
      end
    end

    context 'with merchant_group_id in configuration' do
      before do
        Tappay.configuration.merchant_group_id = 'config_group_123'
      end

      subject { concrete_class.new(valid_options) }

      it 'uses merchant_group_id from configuration' do
        expect(subject.send(:payment_data)[:merchant_group_id]).to eq('config_group_123')
        expect(subject.send(:payment_data)[:merchant_id]).to be_nil
      end
    end

    context 'with merchant_id' do
      before do
        Tappay.configuration.merchant_group_id = nil
      end

      let(:options) { valid_options.merge(merchant_id: 'merchant_123') }
      subject { concrete_class.new(options) }

      it 'uses merchant_id when no merchant_group_id is provided' do
        expect(subject.send(:payment_data)[:merchant_id]).to eq('merchant_123')
        expect(subject.send(:payment_data)[:merchant_group_id]).to be_nil
      end
    end

    context 'without any merchant identifiers' do
      before do
        Tappay.configuration.merchant_id = nil
        Tappay.configuration.merchant_group_id = nil
      end

      let(:options) { valid_options }
      subject { concrete_class.new(options) }

      it 'raises ValidationError' do
        expect { subject.send(:payment_data) }
          .to raise_error(Tappay::ValidationError, /Either merchant_group_id or merchant_id must be provided/)
      end
    end

    context 'with bank_transaction_id' do
      let(:options) { valid_options.merge(bank_transaction_id: 'transaction_123') }
      subject { concrete_class.new(options) }

      it 'includes bank_transaction_id in payment data' do
        expect(subject.send(:payment_data)[:bank_transaction_id]).to eq('transaction_123')
      end
    end

    context 'without bank_transaction_id' do
      let(:options) { valid_options }
      subject { concrete_class.new(options) }

      it 'includes nil bank_transaction_id in payment data' do
        expect(subject.send(:payment_data)[:bank_transaction_id]).to be_nil
      end
    end
  end

  describe '#validate_result_url!' do
    context 'when three_domain_secure is true' do
      context 'without result_url' do
        let(:options) { valid_options.merge(three_domain_secure: true) }
        subject { concrete_class.new(options) }

        it 'raises ValidationError' do
          expect { subject.send(:validate_result_url!) }
            .to raise_error(Tappay::ValidationError, "result_url must be a hash")
        end
      end

      context 'with incomplete result_url' do
        let(:options) do
          valid_options.merge(
            three_domain_secure: true,
            result_url: { frontend_redirect_url: 'https://example.com' }
          )
        end
        subject { concrete_class.new(options) }

        it 'raises ValidationError' do
          expect { subject.send(:validate_result_url!) }
            .to raise_error(Tappay::ValidationError, "result_url must contain both frontend_redirect_url and backend_notify_url")
        end
      end

      context 'with complete result_url' do
        let(:options) do
          valid_options.merge(
            three_domain_secure: true,
            result_url: {
              frontend_redirect_url: 'https://example.com/redirect',
              backend_notify_url: 'https://example.com/notify'
            }
          )
        end
        subject { concrete_class.new(options) }

        it 'does not raise error' do
          expect { subject.send(:validate_result_url!) }.not_to raise_error
        end
      end

      context 'with result_url using string keys' do
        let(:options) do
          valid_options.merge(
            three_domain_secure: true,
            result_url: {
              'frontend_redirect_url' => 'https://example.com/redirect',
              'backend_notify_url' => 'https://example.com/notify'
            }
          )
        end
        subject { concrete_class.new(options) }

        it 'accepts string keys' do
          expect { subject.send(:validate_result_url!) }.not_to raise_error
        end
      end
    end

    context 'when three_domain_secure is false' do
      let(:options) { valid_options.merge(three_domain_secure: false) }
      subject { concrete_class.new(options) }

      it 'does not validate result_url' do
        expect(subject).not_to receive(:validate_result_url!)
        subject.send(:validate_options!)
      end
    end
  end

  describe '#validate_instalment!' do
    context 'with valid instalment values' do
      [0, 3, 6, 12, 18, 24, 30].each do |value|
        context "when instalment is #{value}" do
          let(:options) { valid_options.merge(instalment: value) }
          subject { concrete_class.new(options) }

          it 'does not raise error' do
            expect { subject.send(:validate_instalment!) }.not_to raise_error
          end
        end
      end
    end

    context 'with invalid instalment value' do
      [1, 2, 4, 5, 7, 8, 9, 10, 11, 13, 15, 16, 20, 25, 36, 40].each do |value|
        context "when instalment is #{value}" do
          let(:options) { valid_options.merge(instalment: value) }
          subject { concrete_class.new(options) }

          it 'raises ValidationError' do
            expect { subject.send(:validate_instalment!) }
              .to raise_error(Tappay::ValidationError, "Instalment must be one of: 0, 3, 6, 12, 18, 24, 30")
          end
        end
      end
    end

    context 'with negative instalment value' do
      let(:options) { valid_options.merge(instalment: -1) }
      subject { concrete_class.new(options) }

      it 'raises ValidationError' do
        expect { subject.send(:validate_instalment!) }
          .to raise_error(Tappay::ValidationError, "Instalment must be one of: 0, 3, 6, 12, 18, 24, 30")
      end
    end

    context 'with string instalment value' do
      let(:options) { valid_options.merge(instalment: '6') }
      subject { concrete_class.new(options) }

      it 'does not raise error' do
        expect { subject.send(:validate_instalment!) }.not_to raise_error
      end
    end
  end
end
