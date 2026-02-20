# frozen_string_literal: true

module Truelist
  class Railtie < Rails::Railtie
    initializer 'truelist.configure' do
      Truelist.configure do |config|
        config.api_key ||= ENV.fetch('TRUELIST_API_KEY', nil)
      end
    end
  end
end
