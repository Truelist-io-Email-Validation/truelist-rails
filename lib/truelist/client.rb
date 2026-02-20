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

    private

    def perform_request(email)
      uri = URI("#{@config.base_url}/api/v1/verify")
      http = build_http(uri)

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@config.api_key!}"
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = JSON.generate(email: email)

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
      data = JSON.parse(body)

      Result.new(
        email: email,
        state: data['state'] || 'unknown',
        sub_state: data['sub_state'],
        suggestion: data['suggestion'],
        free_email: data['free_email'] || false,
        role: data['role'] || false,
        disposable: data['disposable'] || false
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
