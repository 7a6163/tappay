# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::CardHolder do
  let(:name) { 'John Doe' }
  let(:email) { 'john@example.com' }
  let(:phone_number) { '+886912345678' }

  let(:card_holder) do
    described_class.new(
      name: name,
      email: email,
      phone_number: phone_number
    )
  end

  describe '#initialize' do
    it 'creates a new card holder with valid attributes' do
      expect(card_holder.name).to eq(name)
      expect(card_holder.email).to eq(email)
      expect(card_holder.phone_number).to eq(phone_number)
    end

    it 'requires all attributes' do
      expect { described_class.new(name: name, email: email) }
        .to raise_error(ArgumentError)
      expect { described_class.new(name: name, phone_number: phone_number) }
        .to raise_error(ArgumentError)
      expect { described_class.new(email: email, phone_number: phone_number) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all attributes' do
      expect(card_holder.to_h).to eq(
        name: name,
        email: email,
        phone_number: phone_number
      )
    end
  end

  describe '#as_json' do
    it 'returns the same as to_h' do
      expect(card_holder.as_json).to eq(card_holder.to_h)
    end
  end
end
