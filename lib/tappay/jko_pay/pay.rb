# frozen_string_literal: true

module Tappay
  module JkoPay
    class Pay < RedirectPayment
      uses_merchant_id :jko_pay_merchant_id
    end
  end
end
