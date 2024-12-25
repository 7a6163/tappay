# frozen_string_literal: true

require 'bundler/setup'
require 'tappay'
require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  enable_coverage :branch
  
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ]
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure Tappay for testing
  config.before(:each) do
    Tappay.configure do |c|
      c.mode = :sandbox
    end
  end
end
