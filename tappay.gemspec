# frozen_string_literal: true

require_relative "lib/tappay/version"

Gem::Specification.new do |spec|
  spec.name = "tappay_ruby"
  spec.version = Tappay::VERSION
  spec.authors = ["Zac"]
  spec.email = ['579103+7a6163@users.noreply.github.com']

  spec.summary = "Ruby wrapper for TapPay payment gateway"
  spec.description = "A Ruby library for integrating with TapPay payment services, supporting credit card payments, refunds, and transaction queries"
  spec.homepage = "https://github.com/7a6163/tappay"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "https://github.com/yourusername/tappay"
  # spec.metadata["changelog_uri"] = "https://github.com/yourusername/tappay/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["{lib}/**/*", "LICENSE.txt", "README.md"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "httparty", "~> 0.21.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "vcr", "~> 6.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
