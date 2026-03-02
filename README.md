# truelist-rails

[![Free tier](https://img.shields.io/badge/free_plan-100_validations-4A7C59?style=flat-square)](https://truelist.io/pricing)
Email validation for Rails, powered by [Truelist.io](https://truelist.io).

[![Gem Version](https://badge.fury.io/rb/truelist-rails.svg)](https://badge.fury.io/rb/truelist-rails)
[![CI](https://github.com/Truelist-io-Email-Validation/truelist-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/Truelist-io-Email-Validation/truelist-rails/actions/workflows/ci.yml)

Validate email deliverability in your Rails models with a single line:

```ruby
validates :email, deliverable: true
```

Truelist checks whether an email address actually exists and can receive mail, catching typos, disposable addresses, and invalid mailboxes before they hit your database.

> **Start free** — 100 validations + 10 enhanced credits, no credit card required.
> [Get your API key →](https://app.truelist.io/signup?utm_source=github&utm_medium=readme&utm_campaign=free-plan&utm_content=truelist-rails)

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

  # Whether "accept_all" emails (domains that accept all addresses) pass validation.
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

### Reject accept_all emails

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

result.state       # => "ok", "email_invalid", "accept_all", or "unknown"
result.sub_state   # => "email_ok", "is_disposable", "is_role", etc.
result.valid?      # => true when state is "ok" (or "accept_all" with allow_risky)
result.invalid?    # => true when state is "email_invalid"
result.accept_all? # => true when state is "accept_all"
result.unknown?    # => true when state is "unknown"

result.email        # => the validated email address
result.suggestion   # => suggested correction, if available
result.domain       # => email domain
result.canonical    # => local part of the email
result.mx_record    # => MX record for the domain
result.first_name   # => first name, if available
result.last_name    # => last name, if available
result.verified_at  # => timestamp of verification
result.disposable?  # => whether it's a disposable/temporary address (sub_state)
result.role?        # => whether it's a role address (sub_state)
```

### Account Info

```ruby
client = Truelist::Client.new
account = client.account

account["email"]                   # => "team@company.com"
account["name"]                    # => "Team Lead"
account["uuid"]                    # => "a3828d19-..."
account["account"]["payment_plan"] # => "pro"
```

### Sub-states

| Sub-state | Meaning |
|-----------|---------|
| `email_ok` | Email is valid and deliverable |
| `is_disposable` | Disposable/temporary email |
| `is_role` | Role-based address (info@, admin@) |
| `failed_smtp_check` | SMTP check failed |
| `failed_mx_check` | Domain has no mail server |
| `failed_spam_trap` | Known spam trap address |
| `failed_no_mailbox` | Mailbox does not exist |
| `failed_greylisted` | Server temporarily rejected (greylisting) |
| `failed_syntax_check` | Email format is invalid |
| `unknown_error` | Could not determine status |

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
    stub_request(:post, "https://api.truelist.io/api/v1/verify_inline")
      .with(query: hash_including(email: /.+/))
      .to_return(
        status: 200,
        body: {
          emails: [{
            address: "user@example.com",
            email_state: "ok",
            email_sub_state: "email_ok"
          }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
```

Or stub at the client level:

```ruby
allow(Truelist::Client).to receive(:new).and_return(
  instance_double(Truelist::Client, validate: Truelist::Result.new(email: "user@example.com", state: "ok"))
)
```

## Requirements

- Ruby >= 3.0
- Rails >= 7.0 (ActiveModel / ActiveSupport)

## Development

```bash
git clone https://github.com/Truelist-io-Email-Validation/truelist-rails.git
cd truelist-rails
bundle install
bundle exec rspec
```


## Getting Started

Sign up for a [free Truelist account](https://app.truelist.io/signup?utm_source=github&utm_medium=readme&utm_campaign=free-plan&utm_content=truelist-rails) to get your API key. The free plan includes 100 validations and 10 enhanced credits — no credit card required.
## License

Released under the [MIT License](LICENSE).
