# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::LinePay::Pay do
  let(:amount) { 1000 }
  let(:details) { 'Test Payment' }
  let(:merchant_id) { 'TEST_MERCHANT' }
  let(:prime) { 'line_pay_prime' }
  let(:payment_url) { 'https://sandbox.tappaysdk.com/tpc/payment/pay-by-prime' }
  let(:frontend_redirect_url) { 'https://example.com/line_pay/result' }
  let(:backend_notify_url) { 'https://example.com/line_pay/notify' }

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

  describe '#execute' do
    let(:response) { { 'status' => 0, 'msg' => 'Success' } }
    let(:payment) { described_class.new(payment_options) }

    before do
      allow_any_instance_of(Tappay::Client).to receive(:post).and_return(response)
    end

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
