# TapPay Ruby Gem

![Gem Version](https://img.shields.io/gem/v/tappay_ruby)
[![RSpec](https://github.com/7a6163/tappay/actions/workflows/rspec.yml/badge.svg)](https://github.com/7a6163/tappay/actions/workflows/rspec.yml)
[![codecov](https://codecov.io/gh/7a6163/tappay/branch/main/graph/badge.svg)](https://codecov.io/gh/7a6163/tappay)

A Ruby library for integrating with TapPay payment services. This gem provides a simple and elegant way to process payments, refunds, and handle instalments through TapPay's payment gateway.

## Features

- Credit card payments (one-time and tokenized)
- Instalment payments
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

  config.instalment_merchant_id = 'your_instalment_merchant_id'.freeze
  config.currency = 'TWD'.freeze
  config.vat_number = 'your_vat_number'.freeze
end
```

### Merchant ID Configuration

The gem supports two types of merchant identification:
1. `merchant_id`: Individual merchant ID
2. `merchant_group_id`: Group merchant ID

Important rules:
- You can set either `merchant_id` or `merchant_group_id` in the configuration, but not both
- When making a payment, you can override the configured merchant ID by providing either `merchant_id` or `merchant_group_id` in the payment options
- If you provide merchant ID in the payment options, it will take precedence over any configuration

Example of overriding merchant ID in payment:
```ruby
# Using merchant_group_id in payment options
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  merchant_group_id: 'group_123',  # This will be used instead of configured merchant_id
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
  # ... other configurations
end
```

### 3. Using Rails Credentials

If you're using Rails, you can use credentials:

```ruby
Tappay.configure do |config|
  config.mode = Rails.env.production? ? :production : :sandbox
  config.partner_key = Rails.application.credentials.tappay[:partner_key].freeze
  config.app_id = Rails.application.credentials.tappay[:app_id].freeze
  # ... other configurations
end
```

## Environment-based Endpoints

The gem automatically handles different endpoints for sandbox and production environments. You don't need to specify the full URLs - just set the mode:

```ruby
# For sandbox (default)
config.mode = :sandbox  # Uses https://sandbox.tappaysdk.com/...

# For production
config.mode = :production  # Uses https://prod.tappaysdk.com/...
```

## Card Holder Information

You can provide cardholder information in two ways:

### 1. Using CardHolder Object (Recommended)

```ruby
# Create a CardHolder object
card_holder = Tappay::CardHolder.new(
  name: 'John Doe',
  email: 'john@example.com',
  phone_number: '+886923456789'
)

# Use in payment directly
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  order_number: 'ORDER-123',
  card_holder: card_holder  # No need to call as_json
)
```

### 2. Using Hash Directly

```ruby
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  order_number: 'ORDER-123',
  card_holder: {
    name: 'John Doe',
    email: 'john@example.com',
    phone_number: '+886923456789'
  }
)
```

Both approaches are valid and will work the same way. The CardHolder object provides a more structured way to handle cardholder information and includes validation.

## Payment URL

When processing payments, the API response may include a `payment_url` field. This URL is used for redirecting users to complete their payment in scenarios such as:

- 3D Secure verification
- LINE Pay payment page
- JKO Pay payment page

Note: payment_url is not supported for:
- Apple Pay
- Google Pay
- Samsung Pay

Example of handling payment URL in response:
```ruby
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  order_number: 'ORDER-123'
)

if result['status'] == 0
  if result['payment_url']
    # Redirect user to payment page for:
    # - 3D Secure verification
    # - LINE Pay payment
    # - JKO Pay payment
    redirect_to result['payment_url']
  end
end
```

## URL Properties

The `result_url` (JSONObject) property is required when using LINE Pay, JKOPAY, 悠遊付, Atome, Pi錢包, 全盈支付, or when three_domain_secure is true. It contains the following URL fields:

```json
{
  "frontend_redirect_url": "https://example.com/redirect",  // Required - URL where consumer will be redirected after completing the transaction
  "backend_notify_url": "https://example.com/notify",      // Required - URL where your server receives transaction results (only port 443)
  "go_back_url": "https://example.com/back"               // Optional - URL for 3D verification error cases (E.SUN, Cathay United, Taishin banks)
}
```

- `frontend_redirect_url` (String): After the consumer completes the transaction process in LINE Pay, JKOPAY, 悠遊付, Atome, Pi錢包, 全盈支付, or 3D verification, they will be redirected to this frontend URL. Must start with https.

- `backend_notify_url` (String): URL where your server receives transaction results. Must start with https and only supports port 443.

- `go_back_url` (String): For 3D verification transactions, this URL is used when consumers are redirected to the TapPay Error page due to improper operation. This scenario only occurs with E.SUN Bank, Cathay United Bank, and Taishin Bank. You can define this URL in the transaction request or set it in TapPay Portal > Developer Content > System Settings > Redirect Link Settings. It's strongly recommended to define this field for 3D transactions to ensure consumers can return to complete the transaction or view results.

## Usage

### Pay by Prime

Use this method when the customer wants to pay with their credit card without storing the card information. The customer will need to enter their card information for each transaction.

```ruby
# Basic payment with prime
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  order_number: 'ORDER-123',
  currency: 'TWD',
  three_domain_secure: true,  # Enable 3D secure if needed
  remember: true,  # Set to true if you want to store the card for future payments
  card_holder: card_holder  # Optional cardholder information
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

  # Handle payment URL if present (for 3D Secure, LINE Pay, JKO Pay)
  if result['payment_url']
    redirect_to result['payment_url']
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
  three_domain_secure: true,  # Enable 3D secure if needed
  card_holder: card_holder  # Optional cardholder information
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
  instalment: 6,  # 6 monthly installments
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

    # Handle payment URL if present (for 3D Secure)
    if result['payment_url']
      redirect_to result['payment_url']
    end
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

### Example Usage with result_url

```ruby
# Example of payment with result_url for LINE Pay
result = Tappay::LinePay::Pay.create(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  merchant_id: 'your_merchant_id',
  details: 'Product Item',
  result_url: {
    frontend_redirect_url: 'https://example.com/payment/complete',
    backend_notify_url: 'https://example.com/payment/notify',
    go_back_url: 'https://example.com/payment/error'
  }
)

# Example of payment with result_url for 3D verification
result = Tappay::CreditCard::Pay.by_prime(
  prime: 'prime_from_tappay_sdk',
  amount: 100,
  merchant_id: 'your_merchant_id',
  three_domain_secure: true,
  result_url: {
    frontend_redirect_url: 'https://example.com/3d/complete',
    backend_notify_url: 'https://example.com/3d/notify',
    go_back_url: 'https://example.com/3d/error'
  }
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/7a6163/tappay.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
