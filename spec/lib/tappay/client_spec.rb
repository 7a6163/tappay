# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Client do
  let(:client) { described_class.new }
  let(:endpoint) { 'https://sandbox.tappaysdk.com/tpc/payment/pay-by-prime' }
  let(:data) { { key: 'value' } }

  before do
    Tappay.configure do |config|
      config.partner_key = 'test_partner_key'
      config.merchant_id = 'test_merchant_id'
    end
  end

  describe '#post' do
    context 'when request is successful' do
      before do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: { status: 0, msg: 'Success' }.to_json)
      end

      it 'makes a POST request with correct headers' do
        client.post(endpoint, data)
        expect(WebMock).to have_requested(:post, endpoint)
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'x-api-key' => 'test_partner_key'
            }
          )
      end
    end

    context 'when API returns error responses' do
      it 'handles 400 errors' do
        stub_request(:post, endpoint)
          .to_return(status: 400, body: 'Bad Request')

        expect { client.post(endpoint, data) }
          .to raise_error(Tappay::ValidationError, /Invalid request/)
      end

      it 'handles 401 errors' do
        stub_request(:post, endpoint)
          .to_return(status: 401)

        expect { client.post(endpoint, data) }
          .to raise_error(Tappay::ConfigurationError, /Authentication failed/)
      end

      it 'handles 404 errors' do
        stub_request(:post, endpoint)
          .to_return(status: 404)

        expect { client.post(endpoint, data) }
          .to raise_error(Tappay::ConnectionError, /API endpoint not found/)
      end

      it 'handles other HTTP errors' do
        stub_request(:post, endpoint)
          .to_return(status: 500, body: 'Internal Server Error')

        expect { client.post(endpoint, data) }
          .to raise_error(Tappay::ConnectionError, /HTTP Request failed with code 500/)
      end
    end

    context 'when network issues occur' do
      it 'handles connection timeouts' do
        stub_request(:post, endpoint).to_timeout

        expect { client.post(endpoint, data) }
          .to raise_error(Tappay::ConnectionError, /HTTP Request failed/)
      end
    end


  end
end
