# frozen_string_literal: true

RSpec.describe Truelist::Client do
  subject(:client) { described_class.new }

  let(:api_url) { 'https://api.truelist.io/api/v1/verify' }

  let(:valid_response) do
    {
      state: 'valid',
      sub_state: 'ok',
      suggestion: nil,
      free_email: false,
      role: false,
      disposable: false
    }.to_json
  end

  let(:invalid_response) do
    {
      state: 'invalid',
      sub_state: 'failed_no_mailbox',
      suggestion: nil,
      free_email: false,
      role: false,
      disposable: false
    }.to_json
  end

  let(:risky_response) do
    {
      state: 'risky',
      sub_state: 'accept_all',
      suggestion: nil,
      free_email: false,
      role: false,
      disposable: false
    }.to_json
  end

  describe '#validate' do
    context 'with a valid email' do
      before do
        stub_request(:post, api_url)
          .with(
            body: { email: 'user@example.com' }.to_json,
            headers: { 'Authorization' => 'Bearer test_api_key' }
          )
          .to_return(status: 200, body: valid_response)
      end

      it 'returns a valid result' do
        result = client.validate('user@example.com')

        expect(result).to be_a(Truelist::Result)
        expect(result.state).to eq('valid')
        expect(result.sub_state).to eq('ok')
        expect(result.valid?).to be(true)
      end
    end

    context 'with an invalid email' do
      before do
        stub_request(:post, api_url)
          .to_return(status: 200, body: invalid_response)
      end

      it 'returns an invalid result' do
        result = client.validate('bad@example.com')

        expect(result.state).to eq('invalid')
        expect(result.sub_state).to eq('failed_no_mailbox')
        expect(result.invalid?).to be(true)
      end
    end

    context 'with a risky email' do
      before do
        stub_request(:post, api_url)
          .to_return(status: 200, body: risky_response)
      end

      it 'returns a risky result' do
        result = client.validate('info@example.com')

        expect(result.state).to eq('risky')
        expect(result.risky?).to be(true)
      end
    end
  end

  describe 'error handling' do
    it 'raises when API key is missing regardless of raise_on_error setting' do
      Truelist.configuration.api_key = nil
      Truelist.configuration.raise_on_error = false

      stub_request(:post, api_url)

      expect do
        client.validate('user@example.com')
      end.to raise_error(Truelist::AuthenticationError, /API key is not configured/)
    end

    context 'with raise_on_error disabled (default)' do
      it 'returns unknown with error flag on timeout' do
        stub_request(:post, api_url).to_timeout

        result = client.validate('user@example.com')

        expect(result.unknown?).to be(true)
        expect(result.error?).to be(true)
        expect(result.email).to eq('user@example.com')
      end

      it 'returns unknown with error flag on 500 error' do
        stub_request(:post, api_url)
          .to_return(status: 500, body: 'Internal Server Error')

        result = client.validate('user@example.com')

        expect(result.unknown?).to be(true)
        expect(result.error?).to be(true)
      end

      it 'returns unknown with error flag on 429 rate limit' do
        stub_request(:post, api_url)
          .to_return(status: 429, body: 'Rate limit exceeded')

        result = client.validate('user@example.com')

        expect(result.unknown?).to be(true)
        expect(result.error?).to be(true)
      end

      it 'raises AuthenticationError on 401 even with raise_on_error disabled' do
        stub_request(:post, api_url)
          .to_return(status: 401, body: 'Unauthorized')

        expect { client.validate('user@example.com') }.to raise_error(Truelist::AuthenticationError)
      end

      it 'returns unknown with error flag on malformed JSON' do
        stub_request(:post, api_url)
          .to_return(status: 200, body: 'not json')

        result = client.validate('user@example.com')

        expect(result.unknown?).to be(true)
        expect(result.error?).to be(true)
      end
    end

    context 'with raise_on_error enabled' do
      before do
        Truelist.configuration.raise_on_error = true
      end

      it 'raises on timeout' do
        stub_request(:post, api_url).to_timeout

        expect { client.validate('user@example.com') }.to raise_error(StandardError)
      end

      it 'raises RateLimitError on 429' do
        stub_request(:post, api_url)
          .to_return(status: 429, body: 'Rate limit exceeded')

        expect { client.validate('user@example.com') }.to raise_error(Truelist::RateLimitError)
      end

      it 'raises AuthenticationError on 401' do
        stub_request(:post, api_url)
          .to_return(status: 401, body: 'Unauthorized')

        expect { client.validate('user@example.com') }.to raise_error(Truelist::AuthenticationError)
      end

      it 'raises ApiError on 500' do
        stub_request(:post, api_url)
          .to_return(status: 500, body: 'Internal Server Error')

        expect { client.validate('user@example.com') }.to raise_error(Truelist::ApiError)
      end
    end
  end

  describe 'caching' do
    let(:cache_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      require 'active_support/cache'
      Truelist.configuration.cache_store = cache_store
      stub_request(:post, api_url)
        .to_return(status: 200, body: valid_response)
    end

    it 'caches the result after first request' do
      client.validate('user@example.com')
      client.validate('user@example.com')

      expect(a_request(:post, api_url)).to have_been_made.once
    end

    it 'returns the cached result on second call' do
      result1 = client.validate('user@example.com')
      result2 = client.validate('user@example.com')

      expect(result2.state).to eq(result1.state)
      expect(result2.email).to eq(result1.email)
    end

    it 'makes separate requests for different emails' do
      client.validate('user1@example.com')
      client.validate('user2@example.com')

      expect(a_request(:post, api_url)).to have_been_made.twice
    end

    it 'normalizes email case for cache keys' do
      client.validate('User@Example.com')
      client.validate('user@example.com')

      expect(a_request(:post, api_url)).to have_been_made.once
    end

    it 'does not cache unknown/error results' do
      stub_request(:post, api_url)
        .to_return(status: 500, body: 'Internal Server Error')
        .then
        .to_return(status: 200, body: valid_response)

      result1 = client.validate('user@example.com')
      expect(result1.unknown?).to be(true)
      expect(result1.error?).to be(true)

      result2 = client.validate('user@example.com')
      expect(result2.state).to eq('valid')
      expect(result2.error?).to be(false)

      expect(a_request(:post, api_url)).to have_been_made.twice
    end
  end

  describe 'request format' do
    before do
      stub_request(:post, api_url)
        .to_return(status: 200, body: valid_response)
    end

    it 'sends the correct headers' do
      client.validate('user@example.com')

      expect(a_request(:post, api_url).with(
               headers: {
                 'Authorization' => 'Bearer test_api_key',
                 'Content-Type' => 'application/json',
                 'Accept' => 'application/json'
               }
             )).to have_been_made.once
    end

    it 'sends the email in the request body' do
      client.validate('user@example.com')

      expect(a_request(:post, api_url).with(
               body: { email: 'user@example.com' }.to_json
             )).to have_been_made.once
    end
  end
end
