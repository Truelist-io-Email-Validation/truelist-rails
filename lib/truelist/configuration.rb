# frozen_string_literal: true

module Truelist
  class Configuration
    attr_accessor :api_key, :base_url, :timeout, :raise_on_error,
                  :allow_risky, :cache_store, :cache_ttl

    def initialize
      @api_key = ENV.fetch('TRUELIST_API_KEY', nil)
      @base_url = 'https://api.truelist.io'
      @timeout = 10
      @raise_on_error = false
      @allow_risky = true
      @cache_store = nil
      @cache_ttl = 3600 # 1 hour in seconds
    end

    def api_key!
      api_key || raise(Truelist::AuthenticationError,
                       'Truelist API key is not configured. Set TRUELIST_API_KEY or use Truelist.configure.')
    end
  end
end
