# truelist-rails

Email validation for Rails, powered by [Truelist.io](https://truelist.io).

[![Gem Version](https://badge.fury.io/rb/truelist-rails.svg)](https://badge.fury.io/rb/truelist-rails)
[![CI](https://github.com/truelist/truelist-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/truelist/truelist-rails/actions/workflows/ci.yml)

Validate email deliverability in your Rails models with a single line:

```ruby
validates :email, deliverable: true
```

Truelist checks whether an email address actually exists and can receive mail, catching typos, disposable addresses, and invalid mailboxes before they hit your database.

## Installation

Add to your Gemfile:

```ruby
gem "truelist-rails"
```

Then run:

```bash
bundle install
```

## Quick Start

### 1. Configure your API key

Set the `TRUELIST_API_KEY` environment variable, or run the install generator:

```bash
rails generate truelist:install
```

This creates `config/initializers/truelist.rb` where you can configure the gem.

### 2. Add the validator

```ruby
class User < ApplicationRecord
  validates :email, presence: true, deliverable: true
end
```

That's it. Invalid emails will now fail validation with a clear error message.

## Configuration

```ruby
Truelist.configure do |config|
  # Your Truelist API key (required).
  # Defaults to ENV["TRUELIST_API_KEY"].
  config.api_key = ENV["TRUELIST_API_KEY"]

  # API base URL. Change only for testing or proxying.
  config.base_url = "https://api.truelist.io"

  # Request timeout in seconds.
  config.timeout = 10

  # When true, raises Truelist::Error on API failures.
  # When false (default), returns an "unknown" result on errors,
  # allowing the validation to pass gracefully.
  config.raise_on_error = false

  # Whether "risky" emails (accept-all domains, etc.) pass validation.
  config.allow_risky = true

  # Optional cache store for validation results.
  # Accepts any Rails-compatible cache store.
  config.cache_store = Rails.cache

  # How long to cache validation results (in seconds).
  config.cache_ttl = 1.hour
end
```

## Validator Options

### Basic usage

```ruby
validates :email, deliverable: true
```

### Reject risky emails

```ruby
validates :email, deliverable: { allow_risky: false }
```

### Custom error message

```ruby
validates :email, deliverable: { message: "is not a valid email address" }
```

### Combine options

```ruby
validates :email, deliverable: { allow_risky: false, message: "doesn't look right" }
```

### Use with other validators

```ruby
validates :email, presence: true,
                  format: { with: URI::MailTo::EMAIL_REGEXP },
                  deliverable: true
```

The `deliverable` validator skips blank values, so pair it with `presence: true` if the field is required.

## Working with Results Directly

Use the client to validate emails outside of model validations:

```ruby
result = Truelist.validate("user@example.com")

result.state      # => "valid", "invalid", "risky", or "unknown"
result.sub_state  # => "ok", "failed_no_mailbox", "disposable_address", etc.
result.valid?     # => true/false (respects allow_risky config)
result.invalid?   # => true/false
result.risky?     # => true/false
result.unknown?   # => true/false

result.suggestion   # => suggested correction, if available
result.free_email?  # => whether it's a free email provider
result.role?        # => whether it's a role address (info@, admin@, etc.)
result.disposable?  # => whether it's a disposable/temporary address
```

### Sub-states

| Sub-state | Meaning |
|-----------|---------|
| `ok` | Email is valid and deliverable |
| `accept_all` | Domain accepts all emails (risky) |
| `disposable_address` | Disposable/temporary email |
| `role_address` | Role-based address (info@, admin@) |
| `failed_mx_check` | Domain has no mail server |
| `failed_spam_trap` | Known spam trap address |
| `failed_no_mailbox` | Mailbox does not exist |
| `failed_greylisted` | Server temporarily rejected (greylisting) |
| `failed_syntax_check` | Email format is invalid |
| `unknown` | Could not determine status |

## Caching

Enable caching to avoid redundant API calls for recently validated emails:

```ruby
Truelist.configure do |config|
  config.cache_store = Rails.cache
  config.cache_ttl = 1.hour
end
```

The cache key is based on the lowercase, stripped email address. Any Rails-compatible cache store works (Redis, Memcached, file store, etc.).

## Error Handling

By default, API errors (timeouts, rate limits, server errors) return an `unknown` result, allowing validation to pass. This prevents your forms from breaking when the API is unreachable.

To raise exceptions instead:

```ruby
Truelist.configure do |config|
  config.raise_on_error = true
end
```

Exception classes:

- `Truelist::Error` -- base error class
- `Truelist::ApiError` -- unexpected API responses
- `Truelist::AuthenticationError` -- invalid API key (401)
- `Truelist::RateLimitError` -- rate limit exceeded (429)

## Testing

Stub the API in your tests to avoid real HTTP calls. With WebMock:

```ruby
# spec/support/truelist.rb
RSpec.configure do |config|
  config.before do
    stub_request(:post, "https://api.truelist.io/api/v1/verify")
      .to_return(
        status: 200,
        body: { state: "valid", sub_state: "ok" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
```

Or stub at the client level:

```ruby
allow(Truelist::Client).to receive(:new).and_return(
  instance_double(Truelist::Client, validate: Truelist::Result.new(email: "user@example.com", state: "valid"))
)
```

## Requirements

- Ruby >= 3.0
- Rails >= 7.0 (ActiveModel / ActiveSupport)

## Development

```bash
git clone https://github.com/truelist/truelist-rails.git
cd truelist-rails
bundle install
bundle exec rspec
```

## License

Released under the [MIT License](LICENSE).
