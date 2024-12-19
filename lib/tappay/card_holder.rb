module Tappay
  class CardHolder
    attr_reader :name, :email, :phone_number

    def initialize(name:, email:, phone_number:)
      @name = name
      @email = email
      @phone_number = phone_number
    end

    def as_json
      {
        name: name,
        email: email,
        phone_number: phone_number
      }
    end
  end
end
