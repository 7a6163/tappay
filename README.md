# TapPay Ruby Gem

A Ruby library for integrating with TapPay payment services. This gem provides a simple and elegant way to process payments, refunds, and handle instalments through TapPay's payment gateway.

## Features

- Credit card payments (one-time and tokenized)
- Instalment payments
- Refund processing
- Transaction status queries
- Comprehensive error handling
- Configurable sandbox/production environments

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

Configure the gem with your TapPay credentials:

```ruby
Tappay.configure do |config|
  config.partner_key = 'your_partner_key'
  config.merchant_id = 'your_merchant_id'
  config.instalment_merchant_id = 'your_instalment_merchant_id' # Optional
  config.sandbox = true # Set to false for production
end
```

## Usage

### Regular Credit Card Payment

```ruby
payment = Tappay::CreditCard::Pay.new(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  details: 'Product description',
  cardholder: {
    phone_number: '+886923456789',
    name: 'John Doe',
    email: 'john@example.com'
  }
)

begin
  result = payment.execute
  if result['status'] == 0
    # Payment successful
    transaction_id = result['rec_trade_id']
  end
rescue Tappay::PaymentError => e
  # Handle payment error
rescue Tappay::ValidationError => e
  # Handle validation error
end
```

### Instalment Payment (分期付款)

```ruby
payment = Tappay::CreditCard::Instalment.new(
  prime: 'prime_from_tappay_sdk',
  amount: 10000,
  instalment: 6,  # 分6期
  details: 'Product description',
  cardholder: {
    phone_number: '+886923456789',
    name: 'John Doe',
    email: 'john@example.com'
  }
)

begin
  result = payment.execute
  if result['status'] == 0
    # Payment successful
    instalment_info = result['instalment_info']
    number_of_instalments = instalment_info['number_of_instalments']
    first_payment = instalment_info['first_payment']
    each_payment = instalment_info['each_payment']
  end
rescue Tappay::PaymentError => e
  # Handle payment error
end
```

### Refund Processing

```ruby
refund = Tappay::CreditCard::Refund.new(
  transaction_id: 'transaction_id_from_payment',
  amount: 100
)

begin
  result = refund.execute
  if result['status'] == 0
    # Refund successful
  end
rescue Tappay::RefundError => e
  # Handle refund error
end
```

## Error Handling

The gem provides several error classes for different scenarios:

- `Tappay::ConfigurationError`: Missing or invalid configuration
- `Tappay::ConnectionError`: Network or API endpoint issues
- `Tappay::ValidationError`: Invalid parameters
- `Tappay::PaymentError`: Payment processing failed
- `Tappay::RefundError`: Refund processing failed
- `Tappay::APIError`: General API errors with status code and message

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/7a6163/tappay.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
