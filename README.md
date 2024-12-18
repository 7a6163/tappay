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
  config.mode = :sandbox # Set to :production for production environment
end
```

## Usage

### Pay by Prime

Use this method when the customer wants to pay with their credit card without storing the card information. The customer will need to enter their card information for each transaction.

```ruby
# Payment with prime (card info not stored)
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  order_number: 'ORDER-123',
  currency: 'TWD',
  redirect_url: 'https://your-site.com/return',
  three_domain_secure: true,  # Enable 3D secure if needed
  remember: true  # Set to true if you want to store the card for future payments
)

if result['status'] == 0
  # Payment successful
  transaction_id = result['rec_trade_id']
  if result['card_secret']
    # If remember is true, you'll get these tokens
    card_key = result['card_secret']['card_key']
    card_token = result['card_secret']['card_token']
    # Store card_key and card_token securely for future payments
  end
end
```

### Pay by Token

Use this method when the customer has opted to save their card information for future purchases. This provides a more convenient checkout experience as customers don't need to re-enter their card information.

```ruby
# Recurring payment with stored card token
result = Tappay::CreditCard::Pay.by_token(
  card_key: 'stored_card_key',
  card_token: 'stored_card_token',
  amount: 100,
  order_number: 'ORDER-124',
  currency: 'TWD',
  redirect_url: 'https://your-site.com/return',
  three_domain_secure: true  # Enable 3D secure if needed
)

if result['status'] == 0
  # Payment successful
  transaction_id = result['rec_trade_id']
end
```

### Instalment Payment

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

### Error Handling

```ruby
begin
  result = Tappay::CreditCard::Pay.by_prime(
    prime: 'prime_from_tappay_sdk',
    amount: 100,
    order_number: 'ORDER-123'
  )
rescue Tappay::PaymentError => e
  # Handle payment error
  puts e.message
rescue Tappay::ValidationError => e
  # Handle validation error
  puts e.message
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/7a6163/tappay.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
