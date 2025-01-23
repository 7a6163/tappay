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

    it 'sets and gets merchant_group_id' do
      config.merchant_group_id = 'group_123'
      expect(config.merchant_group_id).to eq('group_123')
    end

    it 'sets and gets instalment_merchant_id' do
      config.instalment_merchant_id = 'instalment_123'
      expect(config.instalment_merchant_id).to eq('instalment_123')
    end

    it 'sets and gets line_pay_merchant_id' do
      config.line_pay_merchant_id = 'line_pay_123'
      expect(config.line_pay_merchant_id).to eq('line_pay_123')
    end

    it 'sets and gets jko_pay_merchant_id' do
      config.jko_pay_merchant_id = 'jko_pay_123'
      expect(config.jko_pay_merchant_id).to eq('jko_pay_123')
    end

    it 'sets and gets currency' do
      config.currency = 'TWD'
      expect(config.currency).to eq('TWD')
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

  describe '#validate!' do
    context 'without partner_key' do
      it 'raises ValidationError' do
        expect { config.validate! }
          .to raise_error(Tappay::ValidationError, /partner_key is required/)
      end
    end

    context 'without merchant identifiers' do
      before do
        config.partner_key = 'test_key'
        config.merchant_id = nil
        config.merchant_group_id = nil
      end

      it 'raises ValidationError' do
        expect { config.validate! }
          .to raise_error(Tappay::ValidationError, /Either merchant_id or merchant_group_id is required/)
      end
    end

    context 'with merchant_id' do
      before do
        config.partner_key = 'test_key'
        config.merchant_id = 'test_merchant'
      end

      it 'passes validation' do
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'with merchant_group_id' do
      before do
        config.partner_key = 'test_key'
        config.merchant_group_id = 'test_group'
      end

      it 'passes validation' do
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'with both merchant_id and merchant_group_id' do
      before do
        config.partner_key = 'test_key'
        config.merchant_id = 'test_merchant'
        config.merchant_group_id = 'test_group'
      end

      it 'passes validation' do
        expect { config.validate! }.not_to raise_error
      end
    end
  end

  describe '#mode' do
    context 'when mode is not set' do
      before { config.instance_variable_set(:@mode, nil) }

      it 'defaults to sandbox' do
        expect(config.mode).to eq(:sandbox)
      end
    end

    context 'when mode is set' do
      before { config.mode = :production }

      it 'returns the set mode' do
        expect(config.mode).to eq(:production)
      end
    end
  end
end
