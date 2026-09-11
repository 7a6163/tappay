# frozen_string_literal: true

module Tappay
  module LinePay
    class Pay < RedirectPayment
      uses_merchant_id :line_pay_merchant_id
    end
  end
end
