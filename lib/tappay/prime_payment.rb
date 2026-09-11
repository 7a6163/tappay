# frozen_string_literal: true

module Tappay
  # Payment methods charged with a prime from TapPay's SDK, where TapPay also
  # requires cardholder details. Apple Pay and Google Pay are this and nothing
  # more; the redirect methods add a result_url on top.
  class PrimePayment < PaymentBase
    def endpoint_url
      Tappay::Endpoints::Payment.pay_by_prime_url
    end

    protected

    def payment_data
      super.merge(prime: options[:prime])
    end

    private

    def additional_required_options
      [:prime, :cardholder]
    end
  end
end
