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
  - Apple Pay
- Flexible merchant identification:
  - Support for both `merchant_id` and `merchant_group_id`
  - Automatic fallback handling
  - Priority-based merchant ID resolution
- Universal refund processing for all payment methods
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

### Option 1: Using merchant_id

```ruby
# Using merchant_id with optional payment-specific merchant IDs
Tappay.configure do |config|
  config.partner_key = 'YOUR_PARTNER_KEY'
  config.merchant_id = 'YOUR_MERCHANT_ID'
  config.jko_pay_merchant_id = 'YOUR_JKO_PAY_MERCHANT_ID'  # Optional, falls back to merchant_id if not set
  config.line_pay_merchant_id = 'YOUR_LINE_PAY_MERCHANT_ID'  # Optional, falls back to merchant_id if not set
end
```

### Option 2: Using merchant_group_id

```ruby
# Using merchant_group_id (takes precedence over all other merchant IDs)
Tappay.configure do |config|
  config.partner_key = 'YOUR_PARTNER_KEY'
  config.merchant_group_id = 'YOUR_MERCHANT_GROUP_ID'
  # When merchant_group_id is set, all other merchant IDs will be ignored
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
# One-time payment with prime
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

# Payment with saved card token
result = Tappay::CreditCard::Pay.by_token(
  card_key: 'card_key_from_tappay',
  card_token: 'card_token_from_tappay',
  amount: 1000,
  currency: 'TWD',
  details: 'Order Details',
  ccv_prime: 'ccv_prime_from_tappay'  # Optional: CVV verification
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

# Instalment payment with saved card token
result = Tappay::CreditCard::Instalment.by_token(
  card_key: 'card_key_from_tappay',
  card_token: 'card_token_from_tappay',
  amount: 1000,
  instalment: 12,
  details: 'Order Details',
  ccv_prime: 'ccv_prime_from_tappay'  # Optional: CVV verification
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
  backend_notify_url: 'https://example.com/line_pay/notify',
  cardholder: {
    phone_number: '0912345678',
    name: 'Test User',
    email: 'test@example.com'
  }
).execute
```

### Refund Processing

Process refunds for any payment method:

```ruby
# Process a full refund
result = Tappay::Refund.new(
  rec_trade_id: 'TRANSACTION_ID'
).execute

# Process a partial refund
result = Tappay::Refund.new(
  rec_trade_id: 'TRANSACTION_ID',
  amount: 1000  # Optional: specify amount for partial refund
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
  amount: 1000,
  details: 'Some item',
  frontend_redirect_url: 'https://your-site.com/jko_pay/result',
  backend_notify_url: 'https://your-site.com/jko_pay/notify',
  cardholder: {
    phone_number: '0912345678',
    name: 'Test User',
    email: 'test@example.com'
  }
}

payment = Tappay::JkoPay::Pay.new(payment_options)
result = payment.execute
```

### Transaction Query

Query transaction records with required time range:

```ruby
# Query transactions within a specific time range
result = Tappay::Transaction::Query.new(
  time: {
    start_time: 1706198400,  # Unix timestamp for start time
    end_time: 1706284800     # Unix timestamp for end time
  },
  order_number: 'ORDER123',  # Optional: filter by order number
  records_per_page: 50,      # Optional: default is 50
  page: 0,                   # Optional: default is 0
  order_by: {               # Optional: sort results
    attribute: 'time',
    is_descending: true
  }
).execute

# Access the results
result[:trade_records].each do |record|
  puts "Transaction ID: #{record[:rec_trade_id]}"
  puts "Amount: #{record[:amount]}"
  puts "Status: #{record[:record_status]}"
end
```

Note: The `time` parameter with both `start_time` and `end_time` is required for querying transactions.

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
