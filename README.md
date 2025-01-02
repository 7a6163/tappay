# TapPay Ruby Gem

![Gem Version](https://img.shields.io/gem/v/tappay_ruby)
[![RSpec](https://github.com/7a6163/tappay/actions/workflows/rspec.yml/badge.svg)](https://github.com/7a6163/tappay/actions/workflows/rspec.yml)
[![codecov](https://codecov.io/gh/7a6163/tappay/branch/main/graph/badge.svg)](https://codecov.io/gh/7a6163/tappay)

A Ruby library for integrating with TapPay payment services. This gem provides a simple and elegant way to process payments, refunds, and handle instalments through TapPay's payment gateway.

## Features

- Multiple payment methods:
  - Credit card payments (one-time and tokenized)
  - Instalment payments (3, 6, 12, 18, 24, 30 months)
  - Line Pay
  - JKO Pay
- Flexible merchant identification:
  - Support for both `merchant_id` and `merchant_group_id`
  - Automatic fallback handling
  - Priority-based merchant ID resolution
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
  config.partner_key = 'YOUR_PARTNER_KEY'

  # Primary merchant identification
  # You can use either merchant_id or merchant_group_id
  config.merchant_id = 'YOUR_MERCHANT_ID'
  # OR
  config.merchant_group_id = 'YOUR_MERCHANT_GROUP_ID'

  # Optional merchant IDs for specific payment methods
  # Note: These will be ignored if merchant_group_id is set
  config.jko_pay_merchant_id = 'YOUR_JKO_PAY_MERCHANT_ID'
  config.line_pay_merchant_id = 'YOUR_LINE_PAY_MERCHANT_ID'
  config.instalment_merchant_id = 'YOUR_INSTALMENT_MERCHANT_ID'

  config.mode = :sandbox # or :production
end
```

### Merchant ID Resolution

The gem uses the following priority order when resolving merchant IDs:

1. If `merchant_group_id` is set (either in configuration or options):
   - Uses `merchant_group_id` for all payment types
   - Ignores all other merchant IDs (including specific ones for Line Pay, JKO Pay, etc.)

2. If `merchant_group_id` is not set:
   - For Line Pay: Uses `line_pay_merchant_id` if set, otherwise falls back to `merchant_id`
   - For JKO Pay: Uses `jko_pay_merchant_id` if set, otherwise falls back to `merchant_id`
   - For Instalments: Uses `instalment_merchant_id` if set, otherwise falls back to `merchant_id`
   - For other payment types: Uses `merchant_id`

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

### JKO Pay

#### Configuration

```ruby
Tappay.configure do |config|
  config.partner_key = 'YOUR_PARTNER_KEY'
  config.merchant_id = 'YOUR_MERCHANT_ID'
  config.merchant_group_id = 'YOUR_MERCHANT_GROUP_ID' # Optional, mutually exclusive with merchant_id
  config.jko_pay_merchant_id = 'YOUR_JKO_PAY_MERCHANT_ID' # Optional, falls back to merchant_id if not set
  config.sandbox = true # Set to false for production
end
```

#### Processing a JKO Pay Payment

```ruby
payment_options = {
  prime: 'jko_pay_prime',
  merchant_id: 'YOUR_MERCHANT_ID',
  amount: 1000,
  details: 'Some item',
  frontend_redirect_url: 'https://your-site.com/jko_pay/result',
  backend_notify_url: 'https://your-site.com/jko_pay/notify'
}

payment = Tappay::JkoPay::Pay.new(payment_options)
result = payment.execute
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
