# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::CreditCard::Instalment do
  let(:amount) { 1000 }
  let(:details) { 'Test Instalment Payment' }
  let(:merchant_id) { 'TEST_MERCHANT' }
  let(:prime) { 'test_prime' }
  let(:card_key) { 'test_card_key' }
  let(:card_token) { 'test_card_token' }
  let(:payment_url) { 'https://sandbox.tappaysdk.com/tpc/payment/pay-by-prime' }
  let(:cardholder) do
    Tappay::CardHolder.new(
      name: 'Test User',
      email: 'test@example.com',
      phone_number: '0912345678'
    )
  end

  let(:card_holder) { Tappay::CardHolder.new(phone_number: '0912345678', name: 'Test User', email: 'test@example.com') }
  let(:result_url) do
    {
      frontend_redirect_url: 'https://example.com/redirect',
      backend_notify_url: 'https://example.com/notify'
    }
  end

  let(:valid_options) do
    {
      prime: 'test_prime',
      amount: 1000,
      details: 'Test Payment',
      cardholder: card_holder,
      instalment: 3,
      result_url: result_url
    }
  end

  before do
    allow(Tappay::Endpoints::Payment).to receive(:pay_by_prime_url).and_return(payment_url)
    allow(Tappay::Endpoints::Payment).to receive(:pay_by_token_url).and_return(payment_url)
  end

  describe '.by_prime' do
    it 'returns an InstalmentByPrime instance' do
      expect(described_class.by_prime(valid_options)).to be_a(Tappay::CreditCard::InstalmentByPrime)
    end
  end

  describe '.by_token' do
    let(:token_options) do
      valid_options.merge(
        card_key: 'test_card_key',
        card_token: 'test_card_token',
        ccv_prime: 'test_ccv_prime'
      ).tap { |opts| opts.delete(:prime) }
    end

    it 'returns an InstalmentByToken instance' do
      expect(described_class.by_token(token_options)).to be_a(Tappay::CreditCard::InstalmentByToken)
    end
  end

  describe Tappay::CreditCard::InstalmentByPrime do
    describe '#initialize' do
      it 'initializes with valid options' do
        expect { described_class.new(valid_options) }.not_to raise_error
      end

      it 'validates options on initialization' do
        invalid_options = valid_options.tap { |o| o.delete(:amount) }
        expect { described_class.new(invalid_options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: amount/)
      end
    end

    describe '#validate_result_url_for_instalment!' do
      context 'when three_domain_secure is true' do
        let(:options_with_3ds) { valid_options.merge(three_domain_secure: true) }

        context 'when result_url is missing' do
          let(:invalid_options) { options_with_3ds.tap { |o| o.delete(:result_url) } }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
          end
        end

        context 'when result_url is nil' do
          let(:invalid_options) { options_with_3ds.merge(result_url: nil) }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
          end
        end

        context 'when result_url is not a hash' do
          let(:invalid_options) { options_with_3ds.merge(result_url: 'not a hash') }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
          end
        end

        context 'when result_url is missing frontend_redirect_url' do
          let(:invalid_result_url) do
            {
              backend_notify_url: 'https://example.com/notify'
            }
          end
          let(:invalid_options) { options_with_3ds.merge(result_url: invalid_result_url) }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must contain both frontend_redirect_url and backend_notify_url/)
          end
        end

        context 'when result_url is missing backend_notify_url' do
          let(:invalid_result_url) do
            {
              frontend_redirect_url: 'https://example.com/redirect'
            }
          end
          let(:invalid_options) { options_with_3ds.merge(result_url: invalid_result_url) }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must contain both frontend_redirect_url and backend_notify_url/)
          end
        end

        context 'when result_url has both required URLs' do
          it 'does not raise error' do
            expect { described_class.new(options_with_3ds) }.not_to raise_error
          end
        end
      end

      context 'when three_domain_secure is false' do
        let(:options_without_3ds) { valid_options.merge(three_domain_secure: false) }

        it 'does not validate result_url' do
          invalid_options = options_without_3ds.tap { |o| o.delete(:result_url) }
          expect { described_class.new(invalid_options) }.not_to raise_error
        end
      end

      context 'when three_domain_secure is not provided' do
        it 'does not validate result_url' do
          invalid_options = valid_options.tap { |o| o.delete(:result_url) }
          expect { described_class.new(invalid_options) }.not_to raise_error
        end
      end
    end

    describe '#validate_instalment!' do
      context 'with valid instalment values' do
        it 'does not raise error for valid values' do
          [0, 3, 6, 12, 18, 24, 30].each do |instalment|
            expect {
              described_class.new(valid_options.merge(instalment: instalment))
            }.not_to raise_error
          end
        end
      end

      context 'with invalid instalment values' do
        it 'raises error for invalid values' do
          [1, 2, 4, 5, 7, 8, 9, 10, 11, 13, 15, 16, 20, 25, 36, 40].each do |instalment|
            expect {
              described_class.new(valid_options.merge(instalment: instalment))
            }.to raise_error(Tappay::ValidationError, /Instalment must be one of: 0, 3, 6, 12, 18, 24, 30/)
          end
        end
      end
    end

    describe '#get_merchant_id' do
      context 'when merchant_group_id is configured' do
        before do
          allow(Tappay.configuration).to receive(:merchant_group_id).and_return('GROUP_ID')
          allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return('INSTALMENT_MERCHANT')
        end

        it 'returns nil' do
          expect(described_class.new(valid_options).send(:get_merchant_id)).to be_nil
        end
      end

      context 'when instalment_merchant_id is configured' do
        before do
          allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
          allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return('INSTALMENT_MERCHANT')
          allow(Tappay.configuration).to receive(:merchant_id).and_return('DEFAULT_MERCHANT')
        end

        it 'returns instalment_merchant_id' do
          expect(described_class.new(valid_options).send(:get_merchant_id)).to eq('INSTALMENT_MERCHANT')
        end
      end

      context 'when neither merchant_group_id nor instalment_merchant_id is configured' do
        before do
          allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
          allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return(nil)
          allow(Tappay.configuration).to receive(:merchant_id).and_return('DEFAULT_MERCHANT')
        end

        it 'returns default merchant_id' do
          expect(described_class.new(valid_options).send(:get_merchant_id)).to eq('DEFAULT_MERCHANT')
        end
      end
    end

    describe '#payment_data' do
      before do
        allow(Tappay.configuration).to receive(:merchant_id).and_return('TEST_MERCHANT')
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
        allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return(nil)
      end

      let(:payment) { described_class.new(valid_options) }

      it 'includes remember option with default value' do
        data = payment.send(:payment_data)
        expect(data[:remember]).to be false
      end

      it 'includes remember option with specified value' do
        options = valid_options.merge(remember: true)
        data = described_class.new(options).send(:payment_data)
        expect(data[:remember]).to be true
      end

      it 'includes prime from options' do
        data = payment.send(:payment_data)
        expect(data[:prime]).to eq('test_prime')
      end

      context 'with merchant_id from options' do
        let(:options_with_merchant) { valid_options.merge(merchant_id: 'OPTION_MERCHANT') }

        it 'uses merchant_id from options' do
          data = described_class.new(options_with_merchant).send(:payment_data)
          expect(data[:merchant_id]).to eq('OPTION_MERCHANT')
        end
      end

      context 'with merchant_group_id from options' do
        let(:options_with_group) { valid_options.merge(merchant_group_id: 'OPTION_GROUP') }

        it 'uses merchant_group_id from options' do
          data = described_class.new(options_with_group).send(:payment_data)
          expect(data[:merchant_group_id]).to eq('OPTION_GROUP')
          expect(data).not_to have_key(:merchant_id)
        end
      end

      context 'with optional parameters' do
        let(:options_with_optional) do
          valid_options.merge(
            currency: 'USD',
            order_number: 'ORDER123',
            three_domain_secure: true
          )
        end

        it 'includes optional parameters in payment data' do
          data = described_class.new(options_with_optional).send(:payment_data)
          expect(data[:currency]).to eq('USD')
          expect(data[:order_number]).to eq('ORDER123')
          expect(data[:three_domain_secure]).to be true
        end
      end

      context 'with default values' do
        it 'sets default values correctly' do
          data = described_class.new(valid_options).send(:payment_data)
          expect(data[:currency]).to eq('TWD')
          expect(data[:three_domain_secure]).to be false
        end
      end
    end

    describe '#endpoint_url' do
      let(:payment) { described_class.new(valid_options) }

      it 'returns the correct endpoint URL' do
        expect(payment.endpoint_url).to eq(payment_url)
        expect(Tappay::Endpoints::Payment).to have_received(:pay_by_prime_url)
      end
    end

    describe '#card_holder_data' do
      let(:card_holder) { Tappay::CardHolder.new(phone_number: '0912345678', name: 'Test User', email: 'test@example.com') }
      let(:card_holder_hash) { { phone_number: '0912345678', name: 'Test User', email: 'test@example.com' } }

      context 'when cardholder is a CardHolder instance' do
        let(:options) { valid_options.merge(cardholder: card_holder) }
        let(:payment) { described_class.new(options) }

        it 'converts CardHolder to hash' do
          expect(payment.send(:card_holder_data)).to eq(card_holder_hash)
        end
      end

      context 'when cardholder is a Hash' do
        let(:options) { valid_options.merge(cardholder: card_holder_hash) }
        let(:payment) { described_class.new(options) }

        it 'uses the hash directly' do
          expect(payment.send(:card_holder_data)).to eq(card_holder_hash)
        end
      end

      context 'when cardholder is invalid' do
        let(:options) { valid_options.merge(cardholder: 'invalid') }
        let(:payment) { described_class.new(options) }

        it 'raises ValidationError' do
          expect { payment.send(:card_holder_data) }.to raise_error(Tappay::ValidationError, 'Invalid cardholder format')
        end
      end
    end

    describe '#validate_amount!' do
      context 'with invalid amount' do
        it 'raises error when amount is not a number' do
          options = valid_options.merge(amount: 'invalid')
          expect { described_class.new(options) }
            .to raise_error(Tappay::ValidationError, 'amount must be a number')
        end

        it 'raises error when amount is zero' do
          options = valid_options.merge(amount: 0)
          expect { described_class.new(options) }
            .to raise_error(Tappay::ValidationError, 'amount must be greater than 0')
        end

        it 'raises error when amount is negative' do
          options = valid_options.merge(amount: -100)
          expect { described_class.new(options) }
            .to raise_error(Tappay::ValidationError, 'amount must be greater than 0')
        end
      end
    end

    describe '#validate_result_url!' do
      context 'with invalid result_url' do
        it 'raises error when result_url is not a hash' do
          options = valid_options.merge(three_domain_secure: true, result_url: 'invalid')
          expect { described_class.new(options) }
            .to raise_error(Tappay::ValidationError, 'result_url must be a hash')
        end

        it 'raises error when missing frontend_redirect_url' do
          options = valid_options.merge(
            three_domain_secure: true,
            result_url: { backend_notify_url: 'http://example.com/notify' }
          )
          expect { described_class.new(options) }
            .to raise_error(Tappay::ValidationError, 'result_url must contain both frontend_redirect_url and backend_notify_url')
        end

        it 'raises error when missing backend_notify_url' do
          options = valid_options.merge(
            three_domain_secure: true,
            result_url: { frontend_redirect_url: 'http://example.com/redirect' }
          )
          expect { described_class.new(options) }
            .to raise_error(Tappay::ValidationError, 'result_url must contain both frontend_redirect_url and backend_notify_url')
        end
      end

      context 'with string keys' do
        let(:result_url) do
          {
            'frontend_redirect_url' => 'http://example.com/redirect',
            'backend_notify_url' => 'http://example.com/notify'
          }
        end

        it 'accepts string keys for URLs' do
          options = valid_options.merge(
            three_domain_secure: true,
            result_url: result_url
          )
          expect { described_class.new(options) }.not_to raise_error
        end
      end
    end

    describe '#payment_data' do
      before do
        allow(Tappay.configuration).to receive(:merchant_id).and_return('TEST_MERCHANT')
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
        allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return(nil)
        allow(Tappay.configuration).to receive(:partner_key).and_return('TEST_PARTNER_KEY')
      end

      context 'with cardholder' do
        let(:card_holder) { Tappay::CardHolder.new(phone_number: '0912345678', name: 'Test User', email: 'test@example.com') }
        let(:options_with_cardholder) { valid_options.merge(cardholder: card_holder) }

        it 'includes cardholder data' do
          data = described_class.new(options_with_cardholder).send(:payment_data)
          expect(data[:cardholder]).to eq(card_holder.to_h)
        end
      end

      context 'with result_url' do
        let(:result_url) { { frontend_redirect_url: 'http://example.com/redirect', backend_notify_url: 'http://example.com/notify' } }
        let(:options_with_result_url) { valid_options.merge(result_url: result_url) }

        it 'includes result_url data' do
          data = described_class.new(options_with_result_url).send(:payment_data)
          expect(data[:result_url]).to eq(result_url)
        end
      end

      context 'with instalment' do
        let(:options_with_instalment) { valid_options.merge(instalment: 3) }

        it 'includes instalment data' do
          data = described_class.new(options_with_instalment).send(:payment_data)
          expect(data[:instalment]).to eq(3)
        end
      end

      context 'without optional data' do
        let(:basic_options) do
          {
            amount: 1000,
            details: 'Test Payment',
            prime: 'test_prime',
            cardholder: { name: 'Test User', email: 'test@example.com', phone_number: '0912345678' },
            instalment: 0
          }
        end

        it 'sets default instalment to 0' do
          data = described_class.new(basic_options).send(:payment_data)
          expect(data[:instalment]).to eq(0)
        end
      end
    end
  end

  describe Tappay::CreditCard::InstalmentByToken do
    let(:card_holder) do
      Tappay::CardHolder.new(
        phone_number: '0912345678',
        name: 'Test User',
        email: 'test@example.com'
      )
    end

    let(:result_url) do
      {
        frontend_redirect_url: 'https://example.com/redirect',
        backend_notify_url: 'https://example.com/notify'
      }
    end

    let(:token_options) do
      {
        amount: 1000,
        details: 'Test Payment',
        cardholder: card_holder,
        instalment: 3,
        result_url: result_url,
        card_key: 'test_card_key',
        card_token: 'test_card_token',
        ccv_prime: 'test_ccv_prime'
      }
    end

    describe '#initialize' do
      it 'initializes with valid options' do
        expect { described_class.new(token_options) }.not_to raise_error
      end

      it 'validates options on initialization' do
        invalid_options = token_options.tap { |o| o.delete(:card_key) }
        expect { described_class.new(invalid_options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: card_key/)
      end
    end

    describe '#validate_result_url_for_instalment!' do
      context 'when three_domain_secure is true' do
        let(:options_with_3ds) { token_options.merge(three_domain_secure: true) }

        context 'when result_url is missing' do
          let(:invalid_options) { options_with_3ds.tap { |o| o.delete(:result_url) } }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
          end
        end

        context 'when result_url is nil' do
          let(:invalid_options) { options_with_3ds.merge(result_url: nil) }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
          end
        end

        context 'when result_url is not a hash' do
          let(:invalid_options) { options_with_3ds.merge(result_url: 'not a hash') }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
          end
        end

        context 'when result_url is missing frontend_redirect_url' do
          let(:invalid_result_url) do
            {
              backend_notify_url: 'https://example.com/notify'
            }
          end
          let(:invalid_options) { options_with_3ds.merge(result_url: invalid_result_url) }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must contain both frontend_redirect_url and backend_notify_url/)
          end
        end

        context 'when result_url is missing backend_notify_url' do
          let(:invalid_result_url) do
            {
              frontend_redirect_url: 'https://example.com/redirect'
            }
          end
          let(:invalid_options) { options_with_3ds.merge(result_url: invalid_result_url) }

          it 'raises ValidationError' do
            expect { described_class.new(invalid_options) }
              .to raise_error(Tappay::ValidationError, /result_url must contain both frontend_redirect_url and backend_notify_url/)
          end
        end

        context 'when result_url has both required URLs' do
          it 'does not raise error' do
            expect { described_class.new(options_with_3ds) }.not_to raise_error
          end
        end
      end

      context 'when three_domain_secure is false' do
        let(:options_without_3ds) { token_options.merge(three_domain_secure: false) }

        it 'does not validate result_url' do
          invalid_options = options_without_3ds.tap { |o| o.delete(:result_url) }
          expect { described_class.new(invalid_options) }.not_to raise_error
        end
      end

      context 'when three_domain_secure is not provided' do
        it 'does not validate result_url' do
          invalid_options = token_options.tap { |o| o.delete(:result_url) }
          expect { described_class.new(invalid_options) }.not_to raise_error
        end
      end
    end

    describe '#validate_instalment!' do
      context 'with valid instalment values' do
        it 'does not raise error for valid values' do
          [0, 3, 6, 12, 18, 24, 30].each do |instalment|
            expect {
              described_class.new(token_options.merge(instalment: instalment))
            }.not_to raise_error
          end
        end
      end

      context 'with invalid instalment values' do
        it 'raises error for invalid values' do
          [1, 2, 4, 5, 7, 8, 9, 10, 11, 13, 15, 16, 20, 25, 36, 40].each do |instalment|
            expect {
              described_class.new(token_options.merge(instalment: instalment))
            }.to raise_error(Tappay::ValidationError, /Instalment must be one of: 0, 3, 6, 12, 18, 24, 30/)
          end
        end
      end
    end

    describe '#get_merchant_id' do
      context 'when merchant_group_id is configured' do
        before do
          allow(Tappay.configuration).to receive(:merchant_group_id).and_return('GROUP_ID')
          allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return('INSTALMENT_MERCHANT')
        end

        it 'returns nil' do
          expect(described_class.new(token_options).send(:get_merchant_id)).to be_nil
        end
      end

      context 'when instalment_merchant_id is configured' do
        before do
          allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
          allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return('INSTALMENT_MERCHANT')
          allow(Tappay.configuration).to receive(:merchant_id).and_return('DEFAULT_MERCHANT')
        end

        it 'returns instalment_merchant_id' do
          expect(described_class.new(token_options).send(:get_merchant_id)).to eq('INSTALMENT_MERCHANT')
        end
      end

      context 'when neither merchant_group_id nor instalment_merchant_id is configured' do
        before do
          allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
          allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return(nil)
          allow(Tappay.configuration).to receive(:merchant_id).and_return('DEFAULT_MERCHANT')
        end

        it 'returns default merchant_id' do
          expect(described_class.new(token_options).send(:get_merchant_id)).to eq('DEFAULT_MERCHANT')
        end
      end
    end

    describe '#payment_data' do
      before do
        allow(Tappay.configuration).to receive(:merchant_id).and_return('TEST_MERCHANT')
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
        allow(Tappay.configuration).to receive(:instalment_merchant_id).and_return(nil)
        allow(Tappay.configuration).to receive(:partner_key).and_return('TEST_PARTNER_KEY')
      end

      let(:payment) { described_class.new(token_options) }

      it 'includes all required token data' do
        data = payment.send(:payment_data)
        expect(data[:card_key]).to eq('test_card_key')
        expect(data[:card_token]).to eq('test_card_token')
        expect(data[:ccv_prime]).to eq('test_ccv_prime')
      end

      it 'includes data from parent class' do
        data = payment.send(:payment_data)
        expect(data[:amount]).to eq(1000)
        expect(data[:details]).to eq('Test Payment')
      end

      context 'with merchant_id from options' do
        let(:options_with_merchant) { token_options.merge(merchant_id: 'OPTION_MERCHANT') }

        it 'uses merchant_id from options' do
          data = described_class.new(options_with_merchant).send(:payment_data)
          expect(data[:merchant_id]).to eq('OPTION_MERCHANT')
        end
      end

      context 'with merchant_group_id from options' do
        let(:options_with_group) { token_options.merge(merchant_group_id: 'OPTION_GROUP') }

        it 'uses merchant_group_id from options' do
          data = described_class.new(options_with_group).send(:payment_data)
          expect(data[:merchant_group_id]).to eq('OPTION_GROUP')
          expect(data).not_to have_key(:merchant_id)
        end
      end

      context 'with optional parameters' do
        let(:options_with_optional) do
          token_options.merge(
            currency: 'USD',
            order_number: 'ORDER123',
            three_domain_secure: true
          )
        end

        it 'includes optional parameters in payment data' do
          data = described_class.new(options_with_optional).send(:payment_data)
          expect(data[:currency]).to eq('USD')
          expect(data[:order_number]).to eq('ORDER123')
          expect(data[:three_domain_secure]).to be true
        end
      end

      context 'with default values' do
        it 'sets default values correctly' do
          data = described_class.new(token_options).send(:payment_data)
          expect(data[:currency]).to eq('TWD')
          expect(data[:three_domain_secure]).to be false
          expect(data[:partner_key]).to eq('TEST_PARTNER_KEY')
        end
      end
    end

    describe '#endpoint_url' do
      let(:payment) { described_class.new(token_options) }

      it 'returns the correct endpoint URL' do
        expect(payment.endpoint_url).to eq(payment_url)
        expect(Tappay::Endpoints::Payment).to have_received(:pay_by_token_url)
      end
    end
  end

  describe '.by_prime' do
    subject { described_class.by_prime(valid_options) }

    it 'creates an InstalmentByPrime instance' do
      expect(subject).to be_a(Tappay::CreditCard::InstalmentByPrime)
    end

    context 'when executing the payment' do
      let(:payment_instance) { described_class.by_prime(valid_options) }
      let(:expected_payment_data) do
        {
          prime: 'test_prime',
          partner_key: 'partner_key',
          merchant_id: 'merchant_id',
          amount: 1000,
          details: 'Test Payment',
          instalment: 3,
          cardholder: card_holder.to_h,
          result_url: result_url,
          currency: 'TWD',
          three_domain_secure: false,
          order_number: nil,
          remember: false
        }
      end

      before do
        Tappay.configure do |config|
          config.partner_key = 'partner_key'
          config.merchant_id = 'merchant_id'
        end
      end

      it 'sends the correct payment data' do
        expect(payment_instance).to receive(:post)
          .with(Tappay::Endpoints::Payment.pay_by_prime_url, expected_payment_data)
          .and_return(true)

        payment_instance.execute
      end
    end
  end

  describe '.by_token' do
    let(:token_options) do
      valid_options.merge(
        card_key: 'test_card_key',
        card_token: 'test_card_token',
        ccv_prime: 'test_ccv_prime'
      ).tap { |opts| opts.delete(:prime) }
    end

    subject { described_class.by_token(token_options) }

    it 'creates an InstalmentByToken instance' do
      expect(subject).to be_a(Tappay::CreditCard::InstalmentByToken)
    end

    context 'when executing the payment' do
      let(:payment_instance) { described_class.by_token(token_options) }
      let(:expected_payment_data) do
        {
          card_key: 'test_card_key',
          card_token: 'test_card_token',
          ccv_prime: 'test_ccv_prime',
          partner_key: 'partner_key',
          merchant_id: 'merchant_id',
          amount: 1000,
          details: 'Test Payment',
          instalment: 3,
          cardholder: card_holder.to_h,
          result_url: result_url,
          currency: 'TWD',
          three_domain_secure: false,
          order_number: nil
        }
      end

      before do
        Tappay.configure do |config|
          config.partner_key = 'partner_key'
          config.merchant_id = 'merchant_id'
        end
      end

      it 'sends the correct payment data' do
        expect(payment_instance).to receive(:post)
          .with(Tappay::Endpoints::Payment.pay_by_token_url, expected_payment_data)
          .and_return(true)

        payment_instance.execute
      end
    end
  end

  describe '#validate_result_url_for_instalment!' do
    let(:base_options) do
      {
        amount: 1000,
        details: 'Test Payment',
        cardholder: card_holder,
        instalment: 3
      }
    end

    context 'when three_domain_secure is true' do
      let(:options_with_3ds) { base_options.merge(prime: 'test_prime', three_domain_secure: true) }

      context 'when result_url is missing' do
        let(:invalid_options) { options_with_3ds.tap { |o| o.delete(:result_url) } }

        it 'raises ValidationError' do
          expect { Tappay::CreditCard::InstalmentByPrime.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
        end
      end

      context 'when result_url is nil' do
        let(:invalid_options) { options_with_3ds.merge(result_url: nil) }

        it 'raises ValidationError' do
          expect { Tappay::CreditCard::InstalmentByPrime.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
        end
      end

      context 'when result_url is not a hash' do
        let(:invalid_options) { options_with_3ds.merge(result_url: 'not a hash') }

        it 'raises ValidationError' do
          expect { Tappay::CreditCard::InstalmentByPrime.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
        end
      end

      context 'when result_url is missing frontend_redirect_url' do
        let(:invalid_result_url) do
          {
            backend_notify_url: 'https://example.com/notify'
          }
        end
        let(:invalid_options) { options_with_3ds.merge(result_url: invalid_result_url) }

        it 'raises ValidationError' do
          expect { Tappay::CreditCard::InstalmentByPrime.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url must contain both frontend_redirect_url and backend_notify_url/)
        end
      end

      context 'when result_url is missing backend_notify_url' do
        let(:invalid_result_url) do
          {
            frontend_redirect_url: 'https://example.com/redirect'
          }
        end
        let(:invalid_options) { options_with_3ds.merge(result_url: invalid_result_url) }

        it 'raises ValidationError' do
          expect { Tappay::CreditCard::InstalmentByPrime.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url must contain both frontend_redirect_url and backend_notify_url/)
        end
      end

      context 'when result_url has both required URLs' do
        it 'does not raise error' do
          expect { Tappay::CreditCard::InstalmentByPrime.new(options_with_3ds.merge(result_url: result_url)) }.not_to raise_error
        end
      end
    end

    context 'when three_domain_secure is false' do
      let(:options_without_3ds) { base_options.merge(prime: 'test_prime', three_domain_secure: false) }

      it 'does not validate result_url' do
        invalid_options = options_without_3ds.tap { |o| o.delete(:result_url) }
        expect { Tappay::CreditCard::InstalmentByPrime.new(invalid_options) }.not_to raise_error
      end
    end

    context 'when three_domain_secure is not provided' do
      it 'does not validate result_url' do
        invalid_options = base_options.merge(prime: 'test_prime').tap { |o| o.delete(:result_url) }
        expect { Tappay::CreditCard::InstalmentByPrime.new(invalid_options) }.not_to raise_error
      end
    end
  end
end
