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

    context 'when response parsing fails' do
      it 'handles invalid JSON responses' do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: 'invalid json')
        
        expect { client.post(endpoint, data) }
          .to raise_error(Tappay::ConnectionError, /Invalid JSON response/)
      end

      it 'handles non-zero status in response' do
        response_data = { 'status' => 1, 'msg' => 'Business Error', 'bank_result_code' => 'B001', 'bank_result_msg' => 'Bank Error' }
        stub_request(:post, endpoint)
          .to_return(status: 200, body: response_data.to_json)
        
        expect { client.post(endpoint, data) }
          .to raise_error { |error|
            expect(error).to be_a(Tappay::APIError)
            expect(error.code).to eq(1)
            expect(error.message).to eq('Business Error')
            expect(error.response_data).to eq(response_data)
          }
      end

      it 'accepts status 2 for transaction query endpoint' do
        query_endpoint = 'https://sandbox.tappaysdk.com/tpc/transaction/query'
        stub_request(:post, query_endpoint)
          .to_return(status: 200, body: { status: 2, msg: 'No records found' }.to_json)
        
        expect { client.post(query_endpoint, data) }.not_to raise_error
      end

      it 'raises error for status 2 on non-query endpoints' do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: { status: 2, msg: 'Some message' }.to_json)
        
        expect { client.post(endpoint, data) }
          .to raise_error(Tappay::APIError)
      end
    end
  end
end
