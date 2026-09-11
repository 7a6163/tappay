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

      it 'returns nil for a key the response does not have' do
        expect(client.post(endpoint, data)['no_such_key']).to be_nil
      end

      it 'exposes the HTTP code, body and headers' do
        response = client.post(endpoint, data)
        expect(response.code).to eq(200)
        expect(response.body).to eq({ status: 0, msg: 'Success', data: { id: '123' } }.to_json)
        # Must be the converted Hash: a Net::HTTPResponse answers include? too,
        # so `include('content-type')` alone passes without the to_hash call.
        expect(response.headers).to be_a(Hash)
        expect(response.headers['content-type']).to eq(['application/json'])
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

    # Every TapPay endpoint answers with a JSON object. Anything else means
    # something other than TapPay replied, and there is no result to report -
    # returning the raw body made parsed_response['status'] a String#[]
    # substring search that quietly answers nil.
    describe 'a body that is not a JSON object' do
      def response_for(body)
        Tappay::Response.new(
          instance_double(Net::HTTPResponse, code: '200', body: body, to_hash: {})
        )
      end

      it 'raises on a body that is not JSON at all' do
        expect { response_for('<html>maintenance</html>').parsed_response }
          .to raise_error(Tappay::ConnectionError, /Expected a JSON object/)
      end

      it 'quotes the body it could not parse' do
        expect { response_for('<html>maintenance</html>').parsed_response }
          .to raise_error(Tappay::ConnectionError, %r{<html>maintenance</html>})
      end

      it 'truncates the quoted body at 200 characters' do
        expect { response_for('x' * 250).parsed_response }
          .to raise_error(Tappay::ConnectionError) do |error|
            expect(error.message).to include('x' * 200)
            expect(error.message).not_to include('x' * 201)
          end
      end

      # WebMock turns `body: nil` into an empty String, so a nil body only
      # happens when the Response is built directly, as it is here.
      it 'raises on a nil body' do
        expect { response_for(nil).parsed_response }
          .to raise_error(Tappay::ConnectionError, /Expected a JSON object/)
      end

      # Valid JSON, but an Array cannot be indexed by a String key.
      it 'raises on a JSON array' do
        expect { response_for('[1, 2, 3]').parsed_response }
          .to raise_error(Tappay::ConnectionError, /Expected a JSON object/)
      end

      it 'raises from success? too, rather than answering false' do
        expect { response_for('<html>maintenance</html>').success? }
          .to raise_error(Tappay::ConnectionError)
      end
    end

    context 'when the response is a JSON object with no status key' do
      before do
        stub_request(:post, endpoint).to_return(
          status: 200, body: '{"msg":"no status here"}',
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'is not a success, and does not raise' do
        expect(client.post(endpoint, data).success?).to be false
      end
    end
  end
end
