# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay do
  describe 'Error Classes' do
    it 'defines ConfigurationError' do
      expect { raise Tappay::ConfigurationError }.to raise_error(Tappay::ConfigurationError)
    end

    it 'defines ConnectionError' do
      expect { raise Tappay::ConnectionError }.to raise_error(Tappay::ConnectionError)
    end

    it 'defines ValidationError' do
      expect { raise Tappay::ValidationError }.to raise_error(Tappay::ValidationError)
    end

    it 'defines PaymentError' do
      expect { raise Tappay::PaymentError }.to raise_error(Tappay::PaymentError)
    end

    it 'defines RefundError' do
      expect { raise Tappay::RefundError }.to raise_error(Tappay::RefundError)
    end

    it 'defines QueryError' do
      expect { raise Tappay::QueryError }.to raise_error(Tappay::QueryError)
    end
  end

  describe Tappay::APIError do
    let(:code) { 'E001' }
    let(:message) { 'Invalid parameter' }
    let(:error) { described_class.new(code, message) }

    it 'sets code and message' do
      expect(error.code).to eq(code)
      expect(error.message).to eq(message)
    end

    it 'formats error message correctly' do
      expect(error.to_s).to eq("TapPay API Error (E001): Invalid parameter")
    end
  end
end
