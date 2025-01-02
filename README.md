# TapPay Ruby Gem

![Gem Version](https://img.shields.io/gem/v/tappay_ruby)
[![RSpec](https://github.com/7a6163/tappay/actions/workflows/rspec.yml/badge.svg)](https://github.com/7a6163/tappay/actions/workflows/rspec.yml)
[![codecov](https://codecov.io/gh/7a6163/tappay/branch/main/graph/badge.svg)](https://codecov.io/gh/7a6163/tappay)

A Ruby library for integrating with TapPay payment services. This gem provides a simple and elegant way to process payments, refunds, and handle instalments through TapPay's payment gateway.

## Features

- Multiple payment methods:
  - Credit card payments (one-time and tokenized)
  - Instalment payments (3 to 24 months)
  - Line Pay
- Refund processing
- Transaction status queries
- Comprehensive error handling
- Configurable sandbox/production environments
- Environment-based endpoints management
- Card holder information management

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tappay_ruby'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install tappay_ruby
```

## Configuration

There are several ways to configure the gem:

### 1. Direct Configuration

The simplest way to configure the gem:

```ruby
Tappay.configure do |config|
  # Environment settings
  config.mode = Rails.env.production? ? :production : :sandbox

  # Common settings
  config.partner_key = 'your_partner_key'.freeze
  config.app_id = 'your_app_id'.freeze

  # Merchant settings (use either merchant_id or merchant_group_id, not both)
  config.merchant_id = 'your_merchant_id'.freeze
  # OR
  config.merchant_group_id = 'your_merchant_group_id'.freeze

  # Payment-specific merchant IDs
  config.instalment_merchant_id = 'your_instalment_merchant_id'.freeze
  config.line_pay_merchant_id = 'your_line_pay_merchant_id'.freeze

  config.currency = 'TWD'.freeze
  config.vat_number = 'your_vat_number'.freeze
end
```

### Merchant ID Configuration

The gem supports flexible merchant ID configuration:

1. Global merchant ID:
   - `merchant_id`: Default merchant ID for all payments
   - `merchant_group_id`: Group merchant ID (mutually exclusive with merchant_id)

2. Payment-specific merchant IDs:
   - `instalment_merchant_id`: Specific merchant ID for instalment payments
   - `line_pay_merchant_id`: Specific merchant ID for Line Pay transactions

Merchant ID Priority:
1. Payment options merchant ID (if provided in the payment call)
2. Payment-specific merchant ID (if configured)
3. Global merchant ID

Example of merchant ID usage:
```ruby
# Using default merchant ID
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  order_number: 'ORDER-123'
)

# Using payment-specific merchant ID
# This will automatically use line_pay_merchant_id if configured
result = Tappay::LinePay::Pay.new(
  prime: 'line_pay_prime',
  amount: 100,
  frontend_redirect_url: 'https://example.com/line_pay/result',
  backend_notify_url: 'https://example.com/line_pay/notify'
).execute

# Overriding merchant ID in payment options
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  merchant_id: 'override_merchant_id',  # This takes highest priority
  order_number: 'ORDER-123'
)
```

### 2. Using Environment Variables

For better security, you can use environment variables:

```ruby
Tappay.configure do |config|
  config.mode = Rails.env.production? ? :production : :sandbox
  config.partner_key = ENV['TAPPAY_PARTNER_KEY'].freeze
  config.app_id = ENV['TAPPAY_APP_ID'].freeze
  config.merchant_id = ENV['TAPPAY_MERCHANT_ID'].freeze
  config.line_pay_merchant_id = ENV['TAPPAY_LINE_PAY_MERCHANT_ID'].freeze
  config.instalment_merchant_id = ENV['TAPPAY_INSTALMENT_MERCHANT_ID'].freeze
  # ... other configurations
end
```

## Usage

### Credit Card Payment

```ruby
# One-time payment
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 1000,
  details: 'Order Details',
  cardholder: {
    phone_number: '0912345678',
    name: 'Test User',
    email: 'test@example.com'
  }
)

# Instalment payment (3-30 months)
result = Tappay::CreditCard::Instalment.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 1000,
  instalment: 12,  # 12 months instalment
  details: 'Order Details',
  cardholder: {
    phone_number: '0912345678',
    name: 'Test User',
    email: 'test@example.com'
  }
)
```

### Line Pay

```ruby
# Create Line Pay payment
result = Tappay::LinePay::Pay.new(
  prime: 'line_pay_prime',
  amount: 1000,
  details: 'Order Details',
  frontend_redirect_url: 'https://example.com/line_pay/result',
  backend_notify_url: 'https://example.com/line_pay/notify'
).execute
```

### Error Handling

The gem provides comprehensive error handling:

```ruby
begin
  result = Tappay::CreditCard::Pay.by_prime(
    prime: 'prime_from_tappay_sdk',
    amount: 100,
    order_number: 'ORDER-123'
  )
rescue Tappay::ValidationError => e
  # Handle validation errors (e.g., missing required fields)
  puts "Validation error: #{e.message}"
rescue Tappay::APIError => e
  # Handle API errors (e.g., invalid prime, insufficient balance)
  puts "API error: #{e.message}"
rescue Tappay::Error => e
  # Handle other TapPay errors
  puts "TapPay error: #{e.message}"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/7a6163/tappay.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
