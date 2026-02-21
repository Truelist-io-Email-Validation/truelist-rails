# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Truelist
  class Client
    def initialize(config: Truelist.configuration)
      @config = config
    end

    def validate(email)
      cached = read_cache(email)
      return cached if cached

      result = perform_request(email)
      write_cache(email, result) unless result.unknown?
      result
    end

    def account
      uri = URI("#{@config.base_url}/me")
      http = build_http(uri)

      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@config.api_key!}"
      request['Accept'] = 'application/json'

      response = http.request(request)
      handle_status!(response)
      JSON.parse(response.body)
    rescue Truelist::AuthenticationError
      raise
    rescue StandardError => e
      raise e if @config.raise_on_error

      nil
    end

    private

    def perform_request(email)
      uri = URI("#{@config.base_url}/api/v1/verify_inline")
      uri.query = URI.encode_www_form(email: email)
      http = build_http(uri)

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@config.api_key!}"
      request['Accept'] = 'application/json'

      response = http.request(request)
      handle_response(email, response)
    rescue Truelist::AuthenticationError
      raise
    rescue StandardError => e
      handle_error(email, e)
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = @config.timeout
      http.read_timeout = @config.timeout
      http
    end

    def handle_status!(response)
      case response.code.to_i
      when 200 then nil
      when 401
        raise Truelist::AuthenticationError, 'Invalid API key. Check your Truelist API key configuration.'
      else
        raise Truelist::ApiError, "API returned #{response.code}: #{response.body}"
      end
    end

    def handle_response(email, response)
      case response.code.to_i
      when 200
        parse_success(email, response.body)
      when 401
        raise Truelist::AuthenticationError, 'Invalid API key. Check your Truelist API key configuration.'
      when 429
        handle_error(email, Truelist::RateLimitError.new('Rate limit exceeded'))
      else
        handle_error(email, Truelist::ApiError.new("API returned #{response.code}: #{response.body}"))
      end
    end

    def parse_success(email, body)
      d = JSON.parse(body).dig('emails', 0) || {}
      Result.new(
        email: d['address'] || email, state: d['email_state'] || 'unknown',
        sub_state: d['email_sub_state'], suggestion: d['did_you_mean'],
        domain: d['domain'], canonical: d['canonical'], mx_record: d['mx_record'],
        first_name: d['first_name'], last_name: d['last_name'], verified_at: d['verified_at']
      )
    rescue JSON::ParserError => e
      handle_error(email, e)
    end

    def handle_error(email, error)
      raise error if @config.raise_on_error

      Result.new(email: email, state: 'unknown', error: true)
    end

    def cache_key(email)
      "truelist:validation:#{email.downcase.strip}"
    end

    def read_cache(email)
      return nil unless @config.cache_store

      @config.cache_store.read(cache_key(email))
    end

    def write_cache(email, result)
      return unless @config.cache_store

      @config.cache_store.write(cache_key(email), result, expires_in: @config.cache_ttl)
    end
  end
end
