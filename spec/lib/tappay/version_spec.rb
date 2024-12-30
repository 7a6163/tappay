# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay do
  it 'has a version number' do
    expect(Tappay::VERSION).not_to be_nil
    expect(Tappay::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
