# frozen_string_literal: true

module Tappay
  module GooglePay
    class Pay < PrimePayment
      uses_merchant_id :google_pay_merchant_id
    end
  end
end
