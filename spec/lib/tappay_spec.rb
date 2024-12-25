# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay do
  describe '.configure' do
    it 'yields configuration if block given' do
      described_class.configure do |config|
        expect(config).to be_a(Tappay::Configuration)
      end
    end

    it 'creates new configuration if none exists' do
      described_class.configuration = nil
      described_class.configure
      expect(described_class.configuration).to be_a(Tappay::Configuration)
    end
  end

  describe '.reset' do
    before do
      described_class.configure do |config|
        config.partner_key = 'test_key'
        config.merchant_id = 'test_merchant'
      end
    end

    it 'resets the configuration to defaults' do
      described_class.reset
      expect(described_class.configuration.partner_key).to be_nil
      expect(described_class.configuration.merchant_id).to be_nil
    end
  end
end
