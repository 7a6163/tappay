# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in tappay.gemspec
gemspec

# Mutation testing. Kept out of the gemspec because mutant needs Ruby >= 3.3
# while this gem supports >= 2.7, and out of the default bundle because it is
# slow enough that you only want it deliberately.
#   bundle exec mutant run
group :mutant, optional: true do
  # Gem::Version, not a String compare: '3.10' >= '3.3' is false.
  gem 'mutant-rspec', '~> 0.16' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
end
