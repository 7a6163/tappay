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
  - iPass Money
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

## Upgrading from 1.x to 2.0

Four changes need action. Each replaces a silent wrong answer with a loud one.

**Transaction query timestamps are milliseconds.** 1.x documented seconds.
TapPay accepts a seconds-magnitude range but matches nothing against it, so
`Transaction::Query` returned an empty list for every query. Multiply by 1000:

```ruby
# before - always returned []
time: { start_time: 30.days.ago.to_i, end_time: Time.now.to_i }
# after
time: { start_time: 30.days.ago.to_i * 1000, end_time: Time.now.to_i * 1000 }
```

Out-of-scale values now raise `Tappay::ValidationError` rather than returning
nothing.

**`Response#success?` reflects TapPay's `status`, not the HTTP code.** TapPay
answers a declined card with HTTP 200 and a non-zero `status`, so 1.x reported
failed payments as successful. If you were already checking
`result['status'] == 0` yourself, nothing changes; you can now use `success?`
instead. See [Checking the result](#checking-the-result) for what it does and
does not promise.

**Trade records carry every field TapPay returns.** 1.x kept 12 of roughly 32.
`transaction_time` and `tsp` are gone - they matched nothing in the response
and were always `nil`. The transaction timestamp is `time`, in milliseconds.
Fields such as `refunded_amount`, `is_captured`, `original_amount`,
`bank_result_code` and `bank_result_msg` are now available.

**Some public constants are gone.** Grep before upgrading:

```bash
rg 'Tappay::(PaymentError|RefundError|QueryError)|api_version|Endpoints::Bind|trade_history_url|cap_url'
```

`Tappay::PaymentError`, `Tappay::RefundError` and `Tappay::QueryError` were
never raised by the gem, so they never caught anything - use `success?`.
Removing them matters because `rescue Tappay::PaymentError` now raises
`NameError` when the rescue clause is evaluated, which happens only once some
other exception is already in flight.

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
  config.currency = 'TWD'  # Optional, default for payments that do not pass :currency
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
   - For iPass Money: Uses `ipass_money_merchant_id` if set, otherwise falls back to `merchant_id`
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
).execute

# Payment with saved card token
result = Tappay::CreditCard::Pay.by_token(
  card_key: 'card_key_from_tappay',
  card_token: 'card_token_from_tappay',
  amount: 1000,
  currency: 'TWD',
  details: 'Order Details',
  ccv_prime: 'ccv_prime_from_tappay'  # Optional: CVV verification
).execute

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
).execute

# Instalment payment with saved card token
result = Tappay::CreditCard::Instalment.by_token(
  card_key: 'card_key_from_tappay',
  card_token: 'card_token_from_tappay',
  amount: 1000,
  instalment: 12,
  details: 'Order Details',
  ccv_prime: 'ccv_prime_from_tappay'  # Optional: CVV verification
).execute
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

### iPass Money

#### Configuration

```ruby
Tappay.configure do |config|
  config.partner_key = 'YOUR_PARTNER_KEY'
  config.merchant_id = 'YOUR_MERCHANT_ID'
  config.merchant_group_id = 'YOUR_MERCHANT_GROUP_ID' # Optional, mutually exclusive with merchant_id
  config.ipass_money_merchant_id = 'YOUR_IPASS_MONEY_MERCHANT_ID' # Optional, falls back to merchant_id if not set
  config.sandbox = true # Set to false for production
end
```

#### Processing an iPass Money Payment

```ruby
payment_options = {
  prime: 'ipass_money_prime',
  amount: 1000,
  details: 'Some item',
  frontend_redirect_url: 'https://your-site.com/ipass_money/result',
  backend_notify_url: 'https://your-site.com/ipass_money/notify',
  cardholder: {
    phone_number: '0912345678',
    name: 'Test User',
    email: 'test@example.com'
  }
}

payment = Tappay::IPassMoney::Pay.new(payment_options)
result = payment.execute
```

### Transaction Query

Query transaction records with required time range:

```ruby
# time is required; TapPay caps the range at 90 days
result = Tappay::Transaction::Query.new(
  time: {
    start_time: 1706198400000,  # Unix timestamp in MILLISECONDS
    end_time: 1706284800000     # Unix timestamp in MILLISECONDS
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

Every field TapPay returns for a trade record is passed through verbatim, with
keys symbolized (recursively, so nested objects like `refund_info` and
`card_info` are symbol-keyed too). The gem does not whitelist fields, so
`refunded_amount`, `is_captured`, `bank_result_code`, `bank_result_msg`,
`original_amount`, `time` and the various `*_millis` timestamps are all
available, and fields TapPay adds later work without a gem upgrade. The exact
key set varies by payment method. See
`spec/fixtures/transaction_query_response.json` for a real response.

Two things worth knowing about the records:

- `amount` is what remains after refunds. A fully refunded transaction reports
  `amount: 0` with `original_amount` and `refunded_amount` both set to the
  original charge, so compare `refunded_amount` against `original_amount` to
  tell a partial refund from a full one.
- The transaction timestamp is `time` (milliseconds). `transaction_complete_millis`
  is `0` on records that have not completed.

Note: `time` is required and its timestamps are in **milliseconds**, not
seconds. Seconds are accepted by TapPay but match nothing, so the gem rejects
them with a `ValidationError` rather than returning an empty list. TapPay caps
the range at 90 days.

### Checking the result

`Pay.by_prime` and friends return an unexecuted payment object - call
`execute` to send the request. TapPay reports business failures (declined
card, insufficient funds, expired card) as **HTTP 200 with a non-zero
`status`**, so `success?` checks that status rather than the HTTP code:

```ruby
result = Tappay::CreditCard::Pay.by_prime(...).execute

if result.success?          # status == 0
  result['rec_trade_id']
else
  result['status']          # e.g. 10003
  result['msg']             # e.g. 'Card is declined'
end
```

**`success?` does not mean the money has moved.** It means TapPay accepted and
processed the request. What that implies depends on the payment method:

- **Credit card** - the transaction was authorised. Capture is asynchronous;
  confirm it with `is_captured` from a `Transaction::Query`.
- **LINE Pay / JKO Pay / iPass Money** - only that a `payment_url` was created.
  The customer has not paid yet. Redirect them to `result['payment_url']`, and
  treat your `backend_notify_url` callback plus a `Transaction::Query` as the
  authoritative answer. TapPay's own guidance is to query the Record API before
  showing a result page to the customer.

### Error Handling

The gem provides comprehensive error handling:

```ruby
begin
  result = Tappay::CreditCard::Pay.by_prime(
    prime: 'prime_from_tappay_sdk',
    amount: 100,
    details: 'Order Details',
    order_number: 'ORDER-123'
  ).execute

  # TapPay reports declined cards as HTTP 200 with a non-zero status.
  raise "Payment failed: #{result['msg']}" unless result.success?
rescue Tappay::ValidationError => e
  # Handle validation errors (e.g., missing required fields)
  puts "Validation error: #{e.message}"
rescue Tappay::Error => e
  # Handle other TapPay errors
  puts "TapPay error: #{e.message}"
end
```

The gem raises `Tappay::ValidationError` (bad or missing options),
`Tappay::ConfigurationError` (authentication rejected) and
`Tappay::ConnectionError` (timeout, unreachable endpoint, unparseable
response), all of which inherit from `Tappay::Error`. Business failures are
not exceptions - check `success?`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`bundle exec rspec` for the tests, or `bin/console` for an interactive prompt.

### Mutation testing

Line coverage says a line ran, not that anything checked what it did. Both bugs
fixed in 2.0.0 - a field name that never matched the API and a time filter in
the wrong unit - sat under 100% line coverage for the life of the gem.

[Mutant](https://github.com/mbj/mutant) changes the source in small ways (flips
a boolean, drops a call, swaps an operator) and reruns the suite. A mutation
that survives marks behaviour nothing asserts.

```bash
bundle config set --local with mutant
bundle install
bundle exec mutant run
```

It needs Ruby >= 3.3, so it lives in an optional bundle group rather than the
gemspec - the gem itself supports >= 2.7. Scope is `config/mutant.yml`,
currently `Transaction::Query` and `Response`.

The current score is 96.19% (505 of 525). Mutant exits non-zero whenever
anything survives, and the 20 survivors here are equivalent mutations that no
test can distinguish - inside `module Tappay`, `Client.new` and
`Tappay::Client.new` are the same call, and `is_a?(Hash)` and
`instance_of?(Hash)` differ only for a Hash subclass nothing passes. Each one
is listed in `config/mutant.yml` with its reason, and CI gates on the score
rather than the exit code.

If the score drops, an assertion went missing. Read the new survivor rather
than lowering the floor: the first run here scored 77.90%, and every one of
those gaps was genuine - including two tests that passed whether or not the
code they covered was there at all.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/7a6163/tappay.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
