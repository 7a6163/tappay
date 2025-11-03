# frozen_string_literal: true

require 'pry'
require 'simplecov'
require 'simplecov-cobertura'
require 'webmock/rspec'

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
])

SimpleCov.start do
  track_files 'lib/**/*.rb'
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter 'lib/tappay/version.rb'
  add_filter 'lib/tappay/endpoints.rb'
  add_filter 'lib/tappay.rb'
  add_filter 'lib/tappay_ruby.rb'
  enable_coverage :branch
end

require 'bundler/setup'
require 'tappay'

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
      c.partner_key = 'test_partner_key'
    end
  end
end
