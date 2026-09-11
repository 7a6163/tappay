# frozen_string_literal: true

require 'spec_helper'

# Checks the gem's beliefs about TapPay's Record API against the live sandbox.
#
# Every bug fixed in 2.0.0 was contract drift - a field name that did not
# exist, a time filter in the wrong unit - and no amount of stubbing can catch
# that, because a stub asserts the gem against its own assumptions. One real
# call catches all of it.
#
# Excluded from the default suite. To run:
#
#   export TAPPAY_SANDBOX_PARTNER_KEY=...
#   bundle exec rspec spec/contract --tag contract
#
# Only Transaction::Query is covered. Charging needs a `prime`, which is minted
# by the frontend SDK from a test card, is single-use and expires in seconds -
# there is no server-side way to obtain one, so payment and refund flows cannot
# be exercised from here.
RSpec.describe 'TapPay Record API contract', :contract do
  FIXTURE = File.expand_path('../fixtures/transaction_query_response.json', __dir__)

  let(:partner_key) { ENV.fetch('TAPPAY_SANDBOX_PARTNER_KEY', nil) }
  let(:window) do
    now = Time.now.to_i * 1000
    { start_time: now - (90 * 24 * 60 * 60 * 1000), end_time: now }
  end

  before do
    skip 'set TAPPAY_SANDBOX_PARTNER_KEY to run the contract specs' if partner_key.to_s.empty?

    WebMock.allow_net_connect!
    Tappay.reset
    Tappay.configure do |c|
      c.mode = :sandbox
      c.partner_key = partner_key
    end
  end

  after { WebMock.disable_net_connect! }

  let(:result) do
    Tappay::Transaction::Query.new(time: window, records_per_page: 200).execute
  end

  let(:records) { result[:trade_records] }

  # status 0 is success, 2 is "End of list" - both mean the request was
  # understood. Anything else means the endpoint, the auth or the filter shape
  # is wrong, and this one assertion pins all three.
  it 'accepts a millisecond time window' do
    expect(result[:status]).to eq(0).or eq(2)
    puts "\n  status=#{result[:status]} msg=#{result[:msg].inspect} records=#{records.size}"
  end

  it 'returns the fields the committed fixture claims' do
    skip 'sandbox returned no records in the last 90 days' if records.empty?

    expected = JSON.parse(File.read(FIXTURE))['trade_records']
                   .flat_map(&:keys).map(&:to_sym).uniq
    actual = records.flat_map(&:keys).uniq

    missing = expected - actual
    added = actual - expected

    puts "\n  fixture: #{expected.size} fields, live: #{actual.size} fields"
    puts "  TapPay no longer sends: #{missing.inspect}" if missing.any?
    puts "  TapPay now also sends:  #{added.inspect}" if added.any?

    # A field the fixture claims but the API does not send is the transaction_time
    # bug all over again. A field the API added is informational - the gem passes
    # everything through, so nothing breaks; the fixture just wants re-capturing.
    expect(missing).to be_empty
  end

  # Observed live: 33 records came back alongside status 2. A consumer reading
  # `status == 0` as "there is data" silently discards the final page.
  it 'uses status 2 for the end of the list, not for an empty result' do
    skip 'sandbox returned no records in the last 90 days' if records.empty?
    skip 'sandbox has filled a whole page, so this is not the last one' if records.size >= 200

    expect(result[:status]).to eq(2)
    expect(records).not_to be_empty
  end

  it 'reports the transaction timestamp as `time`, in milliseconds' do
    skip 'sandbox returned no records in the last 90 days' if records.empty?

    record = records.first
    expect(record).to have_key(:time)
    expect(record[:time]).to be_an(Integer)
    expect(record[:time]).to be >= Tappay::Transaction::Query::MILLIS_FLOOR
    expect(record[:time]).to be < Tappay::Transaction::Query::MILLIS_CEILING
  end

  # The fields the refund and capture reconciliation depends on. Losing any of
  # these silently is what the whitelist used to do.
  it 'reports the amounts and capture state refunds are reconciled against' do
    skip 'sandbox returned no records in the last 90 days' if records.empty?

    record = records.first
    expect(record).to include(:record_status, :amount, :original_amount,
                              :refunded_amount, :is_captured, :bank_result_code)
    expect(record[:record_status]).to be_an(Integer)
    expect([true, false]).to include(record[:is_captured])
  end
end
