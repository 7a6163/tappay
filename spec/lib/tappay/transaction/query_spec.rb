# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tappay::Transaction::Query do
  # A real (redacted) Record API response. Hand-written fixtures are what let
  # the old field-name bugs survive - keep this one captured from the API.
  def self.fixture
    JSON.parse(File.read(File.expand_path('../../../fixtures/transaction_query_response.json', __dir__)))
  end

  let(:order_number) { 'TEST123' }
  let(:start_time) { (Time.now.to_i - 86_400) * 1000 }
  let(:end_time) { Time.now.to_i * 1000 }
  let(:time_params) { { start_time: start_time, end_time: end_time } }
  let(:query) { described_class.new(
    time: time_params,
    order_number: order_number,
    records_per_page: 50,
    page: 0,
    order_by: {
      attribute: 'time',
      is_descending: true
    }
  ) }
  let(:client) { instance_double(Tappay::Client) }

  # Client#post returns a Tappay::Response, not a Hash. Stubbing a bare Hash
  # here is what would hide a regression in how execute unwraps it.
  def api_response(hash)
    instance_double(Tappay::Response, parsed_response: hash)
  end

  let(:query_url) { 'https://sandbox.tappaysdk.com/tpc/transaction/query' }

  before do
    allow(Tappay::Client).to receive(:new).and_return(client)
    allow(Tappay::Endpoints::Transaction).to receive(:query_url).and_return(query_url)
  end

  describe '#initialize' do
    context 'with valid parameters' do
      it 'creates a new instance' do
        expect(query).to be_a(described_class)
      end
    end

    context 'with missing time parameter' do
      it 'raises ArgumentError' do
        expect {
          described_class.new(order_number: order_number)
        }.to raise_error(ArgumentError, /missing keyword: :time/)
      end
    end

    context 'with invalid time parameter' do
      it 'raises ValidationError when start_time is missing' do
        expect {
          described_class.new(time: { end_time: end_time })
        }.to raise_error(Tappay::ValidationError, /time parameter must include start_time and end_time/)
      end

      it 'raises ValidationError when end_time is missing' do
        expect {
          described_class.new(time: { start_time: start_time })
        }.to raise_error(Tappay::ValidationError, /time parameter must include start_time and end_time/)
      end

      it 'raises ValidationError when timestamps are not integers' do
        expect {
          described_class.new(time: { start_time: 'invalid', end_time: 'invalid' })
        }.to raise_error(Tappay::ValidationError, /start_time and end_time must be Unix timestamps/)
      end

      it 'raises ValidationError when timestamps are in seconds rather than milliseconds' do
        expect {
          described_class.new(time: { start_time: Time.now.to_i - 86_400, end_time: Time.now.to_i })
        }.to raise_error(Tappay::ValidationError, /must be in milliseconds, not seconds/)
      end

      it 'raises ValidationError when timestamps are too large to be milliseconds' do
        expect {
          described_class.new(time: { start_time: start_time * 1000, end_time: end_time * 1000 })
        }.to raise_error(Tappay::ValidationError, /too large to be milliseconds/)
      end

      it 'raises ValidationError when start_time is later than end_time' do
        expect {
          described_class.new(time: { start_time: end_time + 1, end_time: end_time })
        }.to raise_error(Tappay::ValidationError, /start_time cannot be later than end_time/)
      end
    end
  end

  describe '#execute' do
    context 'when the response contains trade records' do
      let(:response) { self.class.fixture }

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(api_response(response))
      end

      it 'returns parsed transaction data' do
        result = query.execute

        expect(result[:status]).to eq(0)
        expect(result[:msg]).to eq('Success')
        expect(result[:records_per_page]).to eq(20)
        expect(result[:page]).to eq(0)
        expect(result[:total_page_count]).to eq(1)
        expect(result[:number_of_transactions]).to eq(4)
        expect(result[:trade_records]).to be_an(Array)
        records = result[:trade_records]
        expect(records.size).to eq(4)

        # No whitelist: every field TapPay sends survives, symbolized, and the
        # key set legitimately differs per payment method.
        records.zip(response['trade_records']).each do |parsed, raw|
          expect(parsed.keys).to match_array(raw.keys.map(&:to_sym))
        end

        captured = records.find { |r| r[:record_status] == 1 }
        expect(captured).to include(
          is_captured: true,
          refunded_amount: 0,
          original_amount: 10_080,
          amount: 10_080,
          payment_method: 'direct_pay',
          bank_result_code: '00',
          time: 1_788_965_579_563
        )

        # amount is what is left after refunds, not what was charged.
        refunded = records.find { |r| r[:record_status] == 3 }
        expect(refunded).to include(
          original_amount: 4198, refunded_amount: 4198, amount: 0, is_captured: false
        )
        expect(refunded[:instalment_info]).to eq(
          first_payment: 1400, each_payment: 1399, number_of_instalments: 3
        )

        failed = records.find { |r| r[:record_status] == -1 }
        expect(failed[:bank_result_msg]).to eq('該筆交易已逾時，交易失敗')

        # The old whitelist kept 3 of cardholder's 10 fields.
        expect(captured[:cardholder].keys).to include(
          :name, :email, :phone_number, :national_id, :member_id, :address,
          :zip_code, :name_en, :bank_member_id, :phone_number_country_code
        )
        expect(records.find { |r| r[:payment_method] == 'line_pay' }[:pay_info]).to include(
          payment_provider: 'TSP'
        )
      end
    end

    context 'when the response contains no trade records' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 0,
          'trade_records' => []
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(api_response(response))
      end

      it 'returns empty trade records' do
        result = query.execute

        expect(result[:status]).to eq(0)
        expect(result[:msg]).to eq('Success')
        expect(result[:records_per_page]).to eq(50)
        expect(result[:page]).to eq(0)
        expect(result[:total_page_count]).to eq(1)
        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    context 'when no records are found' do
      let(:response) do
        {
          'status' => 2,
          'msg' => 'No records found',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 0,
          'number_of_transactions' => 0,
          'trade_records' => []
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(api_response(response))
      end

      it 'returns empty result with status 2' do
        result = query.execute

        expect(result[:status]).to eq(2)
        expect(result[:msg]).to eq('No records found')
        expect(result[:records_per_page]).to eq(50)
        expect(result[:page]).to eq(0)
        expect(result[:total_page_count]).to eq(0)
        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    context 'when trade_records is nil' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 0,
          'trade_records' => nil
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(api_response(response))
      end

      it 'returns empty trade records' do
        result = query.execute

        expect(result[:status]).to eq(0)
        expect(result[:msg]).to eq('Success')
        expect(result[:records_per_page]).to eq(50)
        expect(result[:page]).to eq(0)
        expect(result[:total_page_count]).to eq(1)
        expect(result[:number_of_transactions]).to eq(0)
        expect(result[:trade_records]).to be_empty
      end
    end

    # These guard the bug class this file exists for: a field TapPay sends
    # going missing without anything failing.
    context 'when TapPay returns fields the gem has never heard of' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'some_future_envelope_field' => 'envelope',
          'trade_records' => [
            { 'rec_trade_id' => 'R1', 'some_future_record_field' => 'record' }
          ]
        }
      end

      before { allow(client).to receive(:post).and_return(api_response(response)) }

      it 'passes them through at the envelope level' do
        expect(query.execute[:some_future_envelope_field]).to eq('envelope')
      end

      it 'passes them through at the record level' do
        expect(query.execute[:trade_records].first[:some_future_record_field]).to eq('record')
      end

      it 'drops nothing the API sent' do
        result = query.execute
        expect(result.keys).to include(*response.keys.map(&:to_sym))
        expect(result[:trade_records].first.keys).to(
          match_array(response['trade_records'].first.keys.map(&:to_sym))
        )
      end
    end

    # A maintenance page, proxy or WAF can return HTTP 200 with an HTML body.
    # parsed_response hands back the raw String in that case, which must not
    # escape as a bare TypeError past callers rescuing Tappay::Error.
    context 'when the body is not a JSON object' do
      before do
        allow(client).to receive(:post).and_return(
          instance_double(Tappay::Response, parsed_response: '<html>maintenance</html>',
                                            body: '<html>maintenance</html>')
        )
      end

      it 'raises a Tappay error rather than a TypeError' do
        expect { query.execute }.to raise_error(Tappay::ConnectionError, /Expected a JSON object/)
      end
    end

    context 'when a field holds an array of objects' do
      let(:response) do
        {
          'status' => 0,
          'trade_records' => [
            { 'rec_trade_id' => 'R1',
              'refund_info' => [{ 'amount' => 400, 'refund_millis' => 1_735_098_633_000 }] }
          ]
        }
      end

      before { allow(client).to receive(:post).and_return(api_response(response)) }

      it 'symbolizes keys inside the array too' do
        expect(query.execute[:trade_records].first[:refund_info]).to eq(
          [{ amount: 400, refund_millis: 1_735_098_633_000 }]
        )
      end
    end

    context 'when cardholder is nil' do
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD',
              'order_number' => order_number,
              'cardholder' => nil
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              order_number: order_number,
              time: time_params
            },
            order_by: {
              attribute: 'time',
              is_descending: true
            }
          }
        ).and_return(api_response(response))
      end

      it 'returns nil for cardholder' do
        result = query.execute
        expect(result[:trade_records].first[:cardholder]).to be_nil
      end
    end
  end

  describe 'optional parameters' do
    context 'without order_number' do
      let(:simple_query) { described_class.new(time: time_params) }
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD'
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              time: time_params
            }
          }
        ).and_return(api_response(response))
      end

      it 'sends request without order_number parameter' do
        result = simple_query.execute
        expect(result[:status]).to eq(0)
        expect(result[:trade_records].first[:amount]).to eq(1000)
      end
    end

    context 'with bank_transaction_id' do
      let(:bank_transaction_id) { 'BANK123' }
      let(:bank_query) { described_class.new(time: time_params, bank_transaction_id: bank_transaction_id) }
      let(:response) do
        {
          'status' => 0,
          'msg' => 'Success',
          'records_per_page' => 50,
          'page' => 0,
          'total_page_count' => 1,
          'number_of_transactions' => 1,
          'trade_records' => [
            {
              'record_status' => 0,
              'rec_trade_id' => 'RECTRADE123',
              'amount' => 1000,
              'currency' => 'TWD',
              'bank_transaction_id' => bank_transaction_id
            }
          ]
        }
      end

      before do
        allow(client).to receive(:post).with(
          query_url,
          {
            partner_key: Tappay.configuration.partner_key,
            records_per_page: 50,
            page: 0,
            filters: {
              bank_transaction_id: bank_transaction_id,
              time: time_params
            }
          }
        ).and_return(api_response(response))
      end

      it 'sends request with bank_transaction_id parameter' do
        result = bank_query.execute
        expect(result[:status]).to eq(0)
        expect(result[:trade_records].first[:bank_transaction_id]).to eq(bank_transaction_id)
      end
    end
  end
end
