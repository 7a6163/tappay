# frozen_string_literal: true

module Tappay
  module ApplePay
    class Pay < PrimePayment
      uses_merchant_id :apple_pay_merchant_id
    end
  end
end
