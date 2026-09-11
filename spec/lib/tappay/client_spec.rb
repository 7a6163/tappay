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

    context 'when request returns a Response object' do
      let(:json_body) { { status: 0, msg: 'Success', data: { id: '123' } }.to_json }

      before do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: json_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a Response object with parsed_response' do
        response = client.post(endpoint, data)
        expect(response.parsed_response).to eq({ 'status' => 0, 'msg' => 'Success', 'data' => { 'id' => '123' } })
      end

      it 'supports hash-like access with []' do
        response = client.post(endpoint, data)
        expect(response['status']).to eq(0)
        expect(response['data']).to eq({ 'id' => '123' })
      end

      it 'returns true for success?' do
        response = client.post(endpoint, data)
        expect(response.success?).to be true
      end
    end

    # TapPay reports declined cards and the like as HTTP 200 with a non-zero
    # status. Treating the HTTP code as the answer marks failed payments as
    # successful ones.
    context 'when the HTTP request succeeds but TapPay reports a failure' do
      before do
        stub_request(:post, endpoint).to_return(
          status: 200,
          body: { status: 10003, msg: 'Card is declined' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'is not a success' do
        expect(client.post(endpoint, data).success?).to be false
      end

      it 'still exposes the status and message' do
        response = client.post(endpoint, data)
        expect(response['status']).to eq(10003)
        expect(response['msg']).to eq('Card is declined')
      end
    end

    context 'when the response has no body' do
      before do
        stub_request(:post, endpoint).to_return(status: 200, body: nil)
      end

      it 'is not a success instead of raising' do
        expect(client.post(endpoint, data).success?).to be false
      end
    end

    context 'when response body is not valid JSON' do
      before do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: 'Not a JSON response')
      end

      it 'is not a success' do
        expect(client.post(endpoint, data).success?).to be false
      end

      it 'returns the raw body when JSON parsing fails' do
        response = client.post(endpoint, data)
        expect(response.parsed_response).to eq('Not a JSON response')
      end
    end
  end
end
