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
    describe '#validate_result_url_for_instalment!' do
      context 'when result_url is missing' do
        let(:invalid_options) { valid_options.tap { |o| o.delete(:result_url) } }

        it 'raises ValidationError' do
          expect { described_class.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url with frontend_redirect_url and backend_notify_url is required for instalment payments/)
        end
      end

      context 'when result_url is missing frontend_redirect_url' do
        let(:invalid_result_url) do
          {
            backend_notify_url: 'https://example.com/notify'
          }
        end
        let(:invalid_options) { valid_options.merge(result_url: invalid_result_url) }

        it 'raises ValidationError' do
          expect { described_class.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url with frontend_redirect_url and backend_notify_url is required for instalment payments/)
        end
      end

      context 'when result_url is missing backend_notify_url' do
        let(:invalid_result_url) do
          {
            frontend_redirect_url: 'https://example.com/redirect'
          }
        end
        let(:invalid_options) { valid_options.merge(result_url: invalid_result_url) }

        it 'raises ValidationError' do
          expect { described_class.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url with frontend_redirect_url and backend_notify_url is required for instalment payments/)
        end
      end

      context 'when result_url has both required URLs' do
        it 'does not raise error' do
          expect { described_class.new(valid_options) }.not_to raise_error
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

    describe '#validate_result_url_for_instalment!' do
      context 'when result_url is missing' do
        let(:invalid_options) { token_options.tap { |o| o.delete(:result_url) } }

        it 'raises ValidationError' do
          expect { described_class.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url with frontend_redirect_url and backend_notify_url is required for instalment payments/)
        end
      end

      context 'when result_url is missing frontend_redirect_url' do
        let(:invalid_result_url) do
          {
            backend_notify_url: 'https://example.com/notify'
          }
        end
        let(:invalid_options) { token_options.merge(result_url: invalid_result_url) }

        it 'raises ValidationError' do
          expect { described_class.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url with frontend_redirect_url and backend_notify_url is required for instalment payments/)
        end
      end

      context 'when result_url is missing backend_notify_url' do
        let(:invalid_result_url) do
          {
            frontend_redirect_url: 'https://example.com/redirect'
          }
        end
        let(:invalid_options) { token_options.merge(result_url: invalid_result_url) }

        it 'raises ValidationError' do
          expect { described_class.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url with frontend_redirect_url and backend_notify_url is required for instalment payments/)
        end
      end

      context 'when result_url has both required URLs' do
        it 'does not raise error' do
          expect { described_class.new(token_options) }.not_to raise_error
        end
      end

      context 'when result_url has nil values' do
        let(:invalid_result_url) do
          {
            frontend_redirect_url: nil,
            backend_notify_url: nil
          }
        end
        let(:invalid_options) { token_options.merge(result_url: invalid_result_url) }

        it 'raises ValidationError' do
          expect { described_class.new(invalid_options) }
            .to raise_error(Tappay::ValidationError, /result_url with frontend_redirect_url and backend_notify_url is required for instalment payments/)
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

    context 'without result_url' do
      subject { Tappay::CreditCard::InstalmentByPrime.new(base_options.merge(prime: 'test_prime')) }

      it 'raises ValidationError' do
        expect { subject.send(:validate_result_url_for_instalment!) }
          .to raise_error(Tappay::ValidationError, /result_url.*required for instalment payments/)
      end
    end

    context 'with incomplete result_url' do
      subject do
        Tappay::CreditCard::InstalmentByPrime.new(
          base_options.merge(
            prime: 'test_prime',
            result_url: { frontend_redirect_url: 'https://example.com' }
          )
        )
      end

      it 'raises ValidationError' do
        expect { subject.send(:validate_result_url_for_instalment!) }
          .to raise_error(Tappay::ValidationError, /result_url.*required for instalment payments/)
      end
    end

    context 'with complete result_url' do
      subject do
        Tappay::CreditCard::InstalmentByPrime.new(
          base_options.merge(
            prime: 'test_prime',
            result_url: result_url
          )
        )
      end

      it 'does not raise error' do
        expect { subject.send(:validate_result_url_for_instalment!) }.not_to raise_error
      end
    end

    context 'with result_url containing nil values' do
      subject do
        Tappay::CreditCard::InstalmentByPrime.new(
          base_options.merge(
            prime: 'test_prime',
            result_url: {
              frontend_redirect_url: nil,
              backend_notify_url: nil
            }
          )
        )
      end

      it 'raises ValidationError' do
        expect { subject.send(:validate_result_url_for_instalment!) }
          .to raise_error(Tappay::ValidationError, /result_url.*required for instalment payments/)
      end
    end
  end
end
