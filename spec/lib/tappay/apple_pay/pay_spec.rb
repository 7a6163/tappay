# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::ApplePay::Pay do
  let(:amount) { 100 }
  let(:details) { 'Test Payment' }
  let(:merchant_id) { 'test_merchant_id' }
  let(:apple_pay_merchant_id) { 'apple_pay_merchant_id' }
  let(:merchant_group_id) { 'merchant_group_id' }
  let(:prime) { 'test_prime' }
  let(:cardholder) do
    Tappay::CardHolder.new(
      name: 'Test User',
      email: 'test@example.com',
      phone_number: '0912345678'
    )
  end
  let(:pay_by_prime_url) { 'https://sandbox.tappaysdk.com/tpc/payment/pay-by-prime' }

  let(:payment_options) do
    {
      amount: amount,
      details: details,
      merchant_id: merchant_id,
      prime: prime,
      cardholder: cardholder
    }
  end

  before do
    allow(Tappay.configuration).to receive(:merchant_id).and_return(merchant_id)
    allow(Tappay.configuration).to receive(:apple_pay_merchant_id).and_return(nil)
    allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
    allow(Tappay::Endpoints::Payment).to receive(:pay_by_prime_url).and_return(pay_by_prime_url)
  end

  describe '#endpoint_url' do
    let(:instance) { described_class.new(payment_options) }

    it 'returns pay_by_prime_url' do
      expect(instance.endpoint_url).to eq(pay_by_prime_url)
    end
  end

  describe '#get_merchant_id' do
    let(:instance) { described_class.new(payment_options) }

    context 'when merchant_group_id is set' do
      before do
        allow(Tappay.configuration).to receive(:merchant_group_id).and_return(merchant_group_id)
      end

      it 'returns nil' do
        expect(instance.send(:get_merchant_id)).to be_nil
      end
    end

    context 'when apple_pay_merchant_id is set' do
      before do
        allow(Tappay.configuration).to receive(:apple_pay_merchant_id).and_return(apple_pay_merchant_id)
      end

      it 'returns apple_pay_merchant_id' do
        expect(instance.send(:get_merchant_id)).to eq(apple_pay_merchant_id)
      end
    end

    context 'when only merchant_id is set' do
      it 'returns merchant_id' do
        expect(instance.send(:get_merchant_id)).to eq(merchant_id)
      end
    end
  end

  describe '#additional_required_options' do
    let(:instance) { described_class.new(payment_options) }

    it 'includes :prime and :cardholder' do
      expect(instance.send(:additional_required_options)).to contain_exactly(:prime, :cardholder)
    end
  end

  describe '#payment_data' do
    let(:instance) { described_class.new(payment_options) }
    let(:base_payment_data) { { amount: amount } }
    
    before do
      allow_any_instance_of(Tappay::PaymentBase).to receive(:payment_data).and_return(base_payment_data)
    end

    it 'merges prime with base payment data' do
      expect(instance.send(:payment_data)).to eq(base_payment_data.merge(prime: prime))
    end
  end

  describe '#initialize' do
    context 'with valid options' do
      it 'creates a new instance' do
        expect { described_class.new(payment_options) }.not_to raise_error
      end
    end

    context 'with missing prime' do
      let(:invalid_options) { payment_options.tap { |opt| opt.delete(:prime) } }

      it 'raises ValidationError' do
        expect { described_class.new(invalid_options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: prime/)
      end
    end

    context 'with missing cardholder' do
      let(:invalid_options) { payment_options.tap { |opt| opt.delete(:cardholder) } }

      it 'raises ValidationError' do
        expect { described_class.new(invalid_options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: cardholder/)
      end
    end

    context 'with missing amount' do
      let(:invalid_options) { payment_options.tap { |opt| opt.delete(:amount) } }

      it 'raises ValidationError' do
        expect { described_class.new(invalid_options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: amount/)
      end
    end

    context 'with missing multiple required fields' do
      let(:invalid_options) { {} }

      it 'raises ValidationError with all missing fields' do
        expect { described_class.new(invalid_options) }
          .to raise_error(Tappay::ValidationError, /Missing required options: amount, details, prime, cardholder/)
      end
    end
  end

  describe '#execute' do
    let(:instance) { described_class.new(payment_options) }
    let(:response) { double('response') }

    before do
      allow(instance).to receive(:post).and_return(response)
    end

    it 'posts to the correct endpoint' do
      expect(instance).to receive(:post).with(
        pay_by_prime_url,
        hash_including(
          amount: amount,
          prime: prime
        )
      )

      instance.execute
    end

    it 'returns response' do
      expect(instance.execute).to eq(response)
    end

    context 'when API returns an error' do
      let(:error_response) { { 'status' => 400, 'msg' => 'Invalid prime' } }

      before do
        allow(instance).to receive(:post).and_return(error_response)
      end

      it 'returns the error response' do
        expect(instance.execute).to eq(error_response)
      end
    end
  end
end
