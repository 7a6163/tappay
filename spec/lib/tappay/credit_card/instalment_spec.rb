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
    allow(Tappay::Endpoints::CreditCard).to receive(:payment_by_prime_url).and_return(payment_url)
    allow(Tappay::Endpoints::CreditCard).to receive(:payment_by_token_url).and_return(payment_url)
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
          .with(Tappay::Endpoints::CreditCard.payment_by_prime_url, expected_payment_data)
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
          .with(Tappay::Endpoints::CreditCard.payment_by_token_url, expected_payment_data)
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
  end
end
