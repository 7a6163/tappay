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



  end
end
