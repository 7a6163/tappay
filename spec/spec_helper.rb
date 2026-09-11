# frozen_string_literal: true

require 'pry'
require 'simplecov'
require 'simplecov-cobertura'
require 'webmock/rspec'

SimpleCov.configure do
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])

  track_files 'lib/**/*.rb'
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter 'lib/tappay/version.rb'
  add_filter 'lib/tappay/endpoints.rb'
  add_filter 'lib/tappay.rb'
  add_filter 'lib/tappay_ruby.rb'
  enable_coverage :branch
end

# Mutant reruns this suite once per mutation; letting SimpleCov run each time
# is wasted work and overwrites coverage/coverage.xml with a 0% report.
SimpleCov.start unless defined?(Mutant)

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

  # Configure Tappay for testing. Tappay.configure mutates the existing
  # configuration rather than replacing it, so without the reset every setting
  # an example makes leaks into the ones after it.
  config.before(:each) do
    Tappay.reset
    Tappay.configure do |c|
      c.mode = :sandbox
      c.partner_key = 'test_partner_key'
    end
  end
end
