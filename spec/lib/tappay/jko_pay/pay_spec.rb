# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::JkoPay::Pay do
  let(:amount) { 1000 }
  let(:details) { 'Test Payment' }
  let(:merchant_id) { 'TEST_MERCHANT' }
  let(:prime) { 'jko_pay_prime' }
  let(:payment_url) { 'https://sandbox.tappaysdk.com/tpc/payment/pay-by-prime' }
  let(:frontend_redirect_url) { 'https://example.com/jko_pay/result' }
  let(:backend_notify_url) { 'https://example.com/jko_pay/notify' }

  let(:payment_options) do
    {
      amount: amount,
      details: details,
      merchant_id: merchant_id,
      prime: prime,
      frontend_redirect_url: frontend_redirect_url,
      backend_notify_url: backend_notify_url
    }
  end

  before do
    allow(Tappay::Endpoints::Payment).to receive(:pay_by_prime_url).and_return(payment_url)
  end

  describe '#endpoint_url' do
    it 'returns the correct endpoint URL' do
      payment = described_class.new(payment_options)
      expect(payment.endpoint_url).to eq(payment_url)
      expect(Tappay::Endpoints::Payment).to have_received(:pay_by_prime_url)
    end
  end

  describe '#get_merchant_id' do
    let(:payment) { described_class.new(payment_options) }
    let(:jko_pay_merchant_id) { 'JKO_PAY_MERCHANT' }

    context 'when jko_pay_merchant_id is configured' do
      before do
        allow(Tappay.configuration).to receive(:jko_pay_merchant_id).and_return(jko_pay_merchant_id)
      end

      it 'uses jko_pay_merchant_id' do
        expect(payment.send(:get_merchant_id)).to eq(jko_pay_merchant_id)
      end
    end

    context 'when jko_pay_merchant_id is not configured' do
      before do
        allow(Tappay.configuration).to receive(:jko_pay_merchant_id).and_return(nil)
        allow(Tappay.configuration).to receive(:merchant_id).and_return(merchant_id)
      end

      it 'falls back to default merchant_id' do
        expect(payment.send(:get_merchant_id)).to eq(merchant_id)
      end
    end
  end

  describe '#execute' do
    let(:response) { { 'status' => 0, 'msg' => 'Success' } }
    let(:payment) { described_class.new(payment_options) }

    before do
      allow_any_instance_of(Tappay::Client).to receive(:post).and_return(response)
    end

    context 'with default options' do
      it 'sends the correct payment data' do
        expected_data = {
          partner_key: Tappay.configuration.partner_key,
          prime: prime,
          merchant_id: merchant_id,
          amount: amount,
          details: details,
          remember: false,
          currency: 'TWD',
          order_number: nil,
          three_domain_secure: false,
          instalment: 0,
          result_url: {
            frontend_redirect_url: frontend_redirect_url,
            backend_notify_url: backend_notify_url
          }
        }

        expect_any_instance_of(Tappay::Client).to receive(:post)
          .with(payment_url, expected_data)
          .and_return(response)

        payment.execute
      end
    end

    context 'with custom remember option' do
      let(:payment_with_remember) do
        described_class.new(payment_options.merge(remember: true))
      end

      it 'sends the correct payment data with remember set to true' do
        expected_data = {
          partner_key: Tappay.configuration.partner_key,
          prime: prime,
          merchant_id: merchant_id,
          amount: amount,
          details: details,
          remember: true,
          currency: 'TWD',
          order_number: nil,
          three_domain_secure: false,
          instalment: 0,
          result_url: {
            frontend_redirect_url: frontend_redirect_url,
            backend_notify_url: backend_notify_url
          }
        }

        expect_any_instance_of(Tappay::Client).to receive(:post)
          .with(payment_url, expected_data)
          .and_return(response)

        payment_with_remember.execute
      end
    end

    context 'with custom currency' do
      let(:payment_with_currency) do
        described_class.new(payment_options.merge(currency: 'USD'))
      end

      it 'sends the correct payment data with custom currency' do
        expected_data = {
          partner_key: Tappay.configuration.partner_key,
          prime: prime,
          merchant_id: merchant_id,
          amount: amount,
          details: details,
          remember: false,
          currency: 'USD',
          order_number: nil,
          three_domain_secure: false,
          instalment: 0,
          result_url: {
            frontend_redirect_url: frontend_redirect_url,
            backend_notify_url: backend_notify_url
          }
        }

        expect_any_instance_of(Tappay::Client).to receive(:post)
          .with(payment_url, expected_data)
          .and_return(response)

        payment_with_currency.execute
      end
    end

    context 'with order number' do
      let(:payment_with_order) do
        described_class.new(payment_options.merge(order_number: 'ORDER123'))
      end

      it 'sends the correct payment data with order number' do
        expected_data = {
          partner_key: Tappay.configuration.partner_key,
          prime: prime,
          merchant_id: merchant_id,
          amount: amount,
          details: details,
          remember: false,
          currency: 'TWD',
          order_number: 'ORDER123',
          three_domain_secure: false,
          instalment: 0,
          result_url: {
            frontend_redirect_url: frontend_redirect_url,
            backend_notify_url: backend_notify_url
          }
        }

        expect_any_instance_of(Tappay::Client).to receive(:post)
          .with(payment_url, expected_data)
          .and_return(response)

        payment_with_order.execute
      end
    end
  end

  context 'with missing required options' do
    it 'raises error when frontend_redirect_url is missing' do
      options = payment_options.reject { |k| k == :frontend_redirect_url }
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /frontend_redirect_url/)
    end

    it 'raises error when backend_notify_url is missing' do
      options = payment_options.reject { |k| k == :backend_notify_url }
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /backend_notify_url/)
    end
  end
end
