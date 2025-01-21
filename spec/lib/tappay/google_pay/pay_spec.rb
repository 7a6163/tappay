# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::GooglePay::Pay do
  let(:amount) { 100 }
  let(:details) { 'Test Payment' }
  let(:merchant_id) { 'test_merchant_id' }
  let(:google_pay_merchant_id) { 'google_pay_merchant_id' }
  let(:merchant_group_id) { 'merchant_group_id' }
  let(:prime) { 'test_prime' }
  let(:cardholder) do
    Tappay::CardHolder.new(
      name: 'Test User',
      email: 'test@example.com',
      phone_number: '0912345678'
    )
  end

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
    allow(Tappay.configuration).to receive(:google_pay_merchant_id).and_return(nil)
    allow(Tappay.configuration).to receive(:merchant_group_id).and_return(nil)
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

    context 'when google_pay_merchant_id is set' do
      before do
        allow(Tappay.configuration).to receive(:google_pay_merchant_id).and_return(google_pay_merchant_id)
      end

      it 'returns google_pay_merchant_id' do
        expect(instance.send(:get_merchant_id)).to eq(google_pay_merchant_id)
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
end
