module Tappay
  class CardHolder
    attr_reader :name, :email, :phone_number

    def initialize(name:, email:, phone_number:)
      @name = name
      @email = email
      @phone_number = phone_number
    end

    def to_h
      {
        name: name,
        email: email,
        phone_number: phone_number
      }
    end
    alias_method :as_json, :to_h
  end
end
