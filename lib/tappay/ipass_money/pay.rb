# frozen_string_literal: true

module Tappay
  module IPassMoney
    class Pay < RedirectPayment
      uses_merchant_id :ipass_money_merchant_id
    end
  end
end
