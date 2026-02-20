# frozen_string_literal: true

require_relative "truelist/version"
require_relative "truelist/configuration"
require_relative "truelist/result"
require_relative "truelist/client"

module Truelist
  class Error < StandardError; end
  class ApiError < Error; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def validate(email)
      Client.new.validate(email)
    end
  end
end

require_relative "truelist/railtie" if defined?(Rails::Railtie)
require_relative "truelist/validators/deliverable_validator"
