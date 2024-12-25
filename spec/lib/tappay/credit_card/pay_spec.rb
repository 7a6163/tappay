# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::CreditCard::Pay do
  let(:amount) { 1000 }
  let(:details) { 'Test Payment' }
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

  before do
    allow(Tappay::Endpoints::CreditCard).to receive(:payment_by_prime_url).and_return(payment_url)
    allow(Tappay::Endpoints::CreditCard).to receive(:payment_by_token_url).and_return(payment_url)
  end

  describe '.by_prime' do
    let(:payment_options) do
      {
        amount: amount,
        details: details,
        merchant_id: merchant_id,
        prime: prime,
        cardholder: cardholder
      }
    end

    it 'creates a PayByPrime instance' do
      payment = described_class.by_prime(payment_options)
      expect(payment).to be_a(Tappay::CreditCard::PayByPrime)
    end

    context 'when executing the payment' do
      let(:response) { { 'status' => 0, 'msg' => 'Success' } }
      let(:payment) { described_class.by_prime(payment_options) }

      before do
        allow_any_instance_of(Tappay::Client).to receive(:post).and_return(response)
      end

      it 'sends the correct payment data' do
        expected_data = {
          partner_key: Tappay.configuration.partner_key,
          merchant_id: merchant_id,
          amount: amount,
          details: details,
          currency: 'TWD',
          order_number: nil,
          redirect_url: nil,
          prime: prime,
          remember: false,
          cardholder: cardholder.to_h,
          three_domain_secure: false
        }

        expect_any_instance_of(Tappay::Client).to receive(:post).with(payment_url, expected_data)
        payment.execute
      end
    end

    context 'with missing required parameters' do
      it 'raises a ValidationError' do
        expect { described_class.by_prime(amount: amount) }.to(
          raise_error(Tappay::ValidationError, /Missing required options/)
        )
      end
    end
  end

  describe '.by_token' do
    let(:payment_options) do
      {
        amount: amount,
        details: details,
        merchant_id: merchant_id,
        card_key: card_key,
        card_token: card_token,
        currency: 'TWD'
      }
    end

    it 'creates a PayByToken instance' do
      payment = described_class.by_token(payment_options)
      expect(payment).to be_a(Tappay::CreditCard::PayByToken)
    end

    context 'when executing the payment' do
      let(:response) { { 'status' => 0, 'msg' => 'Success' } }
      let(:payment) { described_class.by_token(payment_options) }

      before do
        allow_any_instance_of(Tappay::Client).to receive(:post).and_return(response)
      end

      it 'sends the correct payment data' do
        expected_data = {
          partner_key: Tappay.configuration.partner_key,
          merchant_id: merchant_id,
          amount: amount,
          details: details,
          currency: 'TWD',
          order_number: nil,
          redirect_url: nil,
          card_key: card_key,
          card_token: card_token,
          three_domain_secure: false
        }

        expect_any_instance_of(Tappay::Client).to receive(:post).with(payment_url, expected_data)
        payment.execute
      end
    end

    context 'with missing required parameters' do
      it 'raises a ValidationError' do
        expect { described_class.by_token(amount: amount) }.to(
          raise_error(Tappay::ValidationError, /Missing required options/)
        )
      end
    end
  end
end
