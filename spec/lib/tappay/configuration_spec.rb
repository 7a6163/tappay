# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Configuration do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      expect(config.mode).to eq(:sandbox)
      expect(config.api_version).to eq('3')
    end
  end

  describe '#mode=' do
    context 'with valid modes' do
      it 'accepts :sandbox' do
        config.mode = :sandbox
        expect(config.mode).to eq(:sandbox)
      end

      it 'accepts :production' do
        config.mode = :production
        expect(config.mode).to eq(:production)
      end

      it 'accepts string values' do
        config.mode = 'production'
        expect(config.mode).to eq(:production)
      end
    end

    context 'with invalid modes' do
      it 'raises error for invalid modes' do
        expect { config.mode = :invalid }
          .to raise_error(ArgumentError, /Invalid mode/)
      end
    end
  end

  describe '#sandbox?' do
    it 'returns true when mode is sandbox' do
      config.mode = :sandbox
      expect(config.sandbox?).to be true
    end

    it 'returns false when mode is production' do
      config.mode = :production
      expect(config.sandbox?).to be false
    end
  end

  describe '#production?' do
    it 'returns true when mode is production' do
      config.mode = :production
      expect(config.production?).to be true
    end

    it 'returns false when mode is sandbox' do
      config.mode = :sandbox
      expect(config.production?).to be false
    end
  end

  describe 'configuration attributes' do
    it 'sets and gets partner_key' do
      config.partner_key = 'partner_123'
      expect(config.partner_key).to eq('partner_123')
    end

    it 'sets and gets merchant_id' do
      config.merchant_id = 'merchant_123'
      expect(config.merchant_id).to eq('merchant_123')
    end

    it 'sets and gets instalment_merchant_id' do
      config.instalment_merchant_id = 'instalment_123'
      expect(config.instalment_merchant_id).to eq('instalment_123')
    end

    it 'sets and gets app_id' do
      config.app_id = 'app_123'
      expect(config.app_id).to eq('app_123')
    end

    it 'sets and gets currency' do
      config.currency = 'TWD'
      expect(config.currency).to eq('TWD')
    end

    it 'sets and gets vat_number' do
      config.vat_number = '12345678'
      expect(config.vat_number).to eq('12345678')
    end
  end

  describe '#api_version' do
    it 'returns api_version as string' do
      config.api_version = 3
      expect(config.api_version).to eq('3')
    end

    it 'maintains default api_version' do
      expect(config.api_version).to eq('3')
    end
  end
end
