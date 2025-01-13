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
  let(:cardholder) do
    Tappay::CardHolder.new(
      name: 'John Doe',
      email: 'john@example.com',
      phone_number: '+886912345678'
    )
  end

  let(:payment_options) do
    {
      amount: amount,
      details: details,
      merchant_id: merchant_id,
      prime: prime,
      frontend_redirect_url: frontend_redirect_url,
      backend_notify_url: backend_notify_url,
      cardholder: cardholder
    }
  end

  let(:payment) { described_class.new(payment_options) }

  before do
    allow(Tappay::Endpoints::Payment).to receive(:pay_by_prime_url).and_return(payment_url)
  end

  describe '#initialize' do
    context 'with merchant_group_id' do
      let(:merchant_group_id) { 'TEST_GROUP' }
      let(:payment_with_group) do
        described_class.new(payment_options.merge(merchant_group_id: merchant_group_id))
      end

      it 'uses merchant_group_id instead of merchant_id' do
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
        data = payment_with_group.send(:payment_data)
        expect(data).to have_key(:merchant_group_id)
        expect(data).not_to have_key(:merchant_id)
        expect(data[:merchant_group_id]).to eq(merchant_group_id)
      end
    end
  end

  describe '#endpoint_url' do
    it 'returns the correct endpoint URL' do
      expect(payment.endpoint_url).to eq(payment_url)
      expect(Tappay::Endpoints::Payment).to have_received(:pay_by_prime_url)
    end
  end

  describe '#get_merchant_id' do
    let(:line_pay_merchant_id) { 'LINE_PAY_MERCHANT' }

    context 'when line_pay_merchant_id is configured' do
      before do
        allow(Tappay.configuration).to receive(:line_pay_merchant_id).and_return(line_pay_merchant_id)
      end

      it 'uses line_pay_merchant_id' do
        expect(payment.send(:get_merchant_id)).to eq(line_pay_merchant_id)
      end
    end

    context 'when line_pay_merchant_id is not configured' do
      before do
        allow(Tappay.configuration).to receive(:line_pay_merchant_id).and_return(nil)
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
        allow(Tappay.configuration).to receive(:merchant_id).and_return(merchant_id)
      end

      it 'falls back to default merchant_id' do
        expect(payment.send(:get_merchant_id)).to eq(merchant_id)
      end
    end

    context 'when merchant_group_id is configured' do
      before do
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return('GROUP_ID')
      end

      it 'returns nil' do
        expect(payment.send(:get_merchant_id)).to be_nil
      end
    end

    context 'when both merchant_group_id and line_pay_merchant_id are configured' do
      before do
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return('GROUP_ID')
        allow(Tappay.configuration).to receive(:line_pay_merchant_id).and_return('LINE_PAY_MERCHANT')
      end

      it 'returns nil due to merchant_group_id taking precedence' do
        expect(payment.send(:get_merchant_id)).to be_nil
      end
    end
  end

  describe '#payment_data' do
    it 'includes required payment data' do
      data = payment.send(:payment_data)
      expect(data[:prime]).to eq(prime)
      expect(data[:result_url]).to eq(
        frontend_redirect_url: frontend_redirect_url,
        backend_notify_url: backend_notify_url
      )
      expect(data).not_to have_key(:remember)
    end

    context 'with optional parameters' do
      let(:optional_params) do
        {
          currency: 'USD',
          order_number: 'ORDER123',
          three_domain_secure: true,
          result_url: {
            frontend_redirect_url: frontend_redirect_url,
            backend_notify_url: backend_notify_url
          }
        }
      end

      let(:payment_with_options) do
        described_class.new(payment_options.merge(optional_params))
      end

      it 'includes optional parameters in payment data' do
        data = payment_with_options.send(:payment_data)
        expect(data[:currency]).to eq('USD')
        expect(data[:order_number]).to eq('ORDER123')
        expect(data[:three_domain_secure]).to be true
        expect(data[:result_url]).to eq(
          frontend_redirect_url: frontend_redirect_url,
          backend_notify_url: backend_notify_url
        )
      end
    end
  end

  describe '#execute' do
    let(:response) { { 'status' => 0, 'msg' => 'Success' } }

    before do
      allow_any_instance_of(described_class).to receive(:post).and_return(response)
    end

    it 'makes a payment request' do
      expect(payment.execute).to eq(response)
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

    it 'raises error when prime is missing' do
      options = payment_options.reject { |k| k == :prime }
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /prime/)
    end

    it 'raises error when cardholder is missing' do
      options = payment_options.reject { |k| k == :cardholder }
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /cardholder/)
    end
  end

  context 'with cardholder' do
    let(:cardholder_hash) do
      {
        name: 'Test User',
        email: 'test@example.com',
        phone_number: '0912345678'
      }
    end

    it 'accepts cardholder as a hash' do
      options = payment_options.merge(cardholder: cardholder_hash)
      payment = described_class.new(options)
      data = payment.send(:payment_data)
      expect(data[:cardholder]).to eq(cardholder_hash)
    end

    it 'accepts cardholder as a CardHolder object' do
      cardholder = Tappay::CardHolder.new(
        name: cardholder_hash[:name],
        email: cardholder_hash[:email],
        phone_number: cardholder_hash[:phone_number]
      )
      options = payment_options.merge(cardholder: cardholder)
      payment = described_class.new(options)
      data = payment.send(:payment_data)
      expect(data[:cardholder]).to eq(cardholder_hash)
    end

    it 'raises error for invalid cardholder format' do
      options = payment_options.merge(cardholder: 'invalid')
      payment = described_class.new(options)
      expect { payment.send(:card_holder_data) }
        .to raise_error(Tappay::ValidationError, /Invalid cardholder format/)
    end
  end

  context 'with instalment' do
    it 'accepts valid instalment values' do
      [0, 3, 6, 12, 18, 24, 30].each do |value|
        options = payment_options.merge(instalment: value)
        expect { described_class.new(options) }.not_to raise_error
      end
    end

    it 'raises error for invalid instalment value' do
      options = payment_options.merge(instalment: 5)
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /Instalment must be one of:/)
    end

    it 'converts string instalment to integer' do
      options = payment_options.merge(instalment: '3')
      expect { described_class.new(options) }.not_to raise_error
    end
  end

  context 'with result_url' do
    it 'raises error when result_url is not a hash' do
      options = payment_options.merge(
        three_domain_secure: true,
        result_url: 'not a hash'
      )
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
    end

    it 'raises error when result_url is nil' do
      options = payment_options.merge(
        three_domain_secure: true,
        result_url: nil
      )
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /result_url must be a hash/)
    end

    it 'raises error when result_url is missing required fields' do
      options = payment_options.merge(
        three_domain_secure: true,
        result_url: { frontend_redirect_url: 'https://example.com' }
      )
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /must contain both frontend_redirect_url and backend_notify_url/)
    end

    it 'accepts result_url with string keys' do
      options = payment_options.merge(
        three_domain_secure: true,
        result_url: {
          'frontend_redirect_url' => frontend_redirect_url,
          'backend_notify_url' => backend_notify_url
        }
      )
      expect { described_class.new(options) }.not_to raise_error
    end

    it 'accepts result_url with mixed string and symbol keys' do
      options = payment_options.merge(
        three_domain_secure: true,
        result_url: {
          'frontend_redirect_url' => frontend_redirect_url,
          backend_notify_url: backend_notify_url
        }
      )
      expect { described_class.new(options) }.not_to raise_error
    end

    it 'accepts result_url with all symbol keys' do
      options = payment_options.merge(
        three_domain_secure: true,
        result_url: {
          frontend_redirect_url: frontend_redirect_url,
          backend_notify_url: backend_notify_url
        }
      )
      expect { described_class.new(options) }.not_to raise_error
    end
  end

  context 'with invalid amount' do
    it 'raises error when amount is not a number' do
      options = payment_options.merge(amount: 'invalid')
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /amount must be a number/)
    end

    it 'raises error when amount is not positive' do
      options = payment_options.merge(amount: 0)
      expect { described_class.new(options) }
        .to raise_error(Tappay::ValidationError, /amount must be greater than 0/)
    end
  end
end
