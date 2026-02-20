# frozen_string_literal: true

Truelist.configure do |config|
  # Your Truelist API key. Defaults to ENV["TRUELIST_API_KEY"].
  # config.api_key = ENV["TRUELIST_API_KEY"]

  # API base URL (change only for testing/proxying).
  # config.base_url = "https://api.truelist.io"

  # Request timeout in seconds.
  # config.timeout = 10

  # When true, raises Truelist::Error on API failures.
  # When false (default), returns an "unknown" result on errors.
  # config.raise_on_error = false

  # Whether "risky" emails pass validation.
  # config.allow_risky = true

  # Optional cache store for validation results.
  # Uses any Rails-compatible cache store (e.g., Rails.cache).
  # config.cache_store = Rails.cache

  # How long to cache validation results.
  # config.cache_ttl = 1.hour
end
