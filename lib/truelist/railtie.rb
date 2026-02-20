# frozen_string_literal: true

module Truelist
  class Railtie < Rails::Railtie
    initializer "truelist.configure" do
      Truelist.configure do |config|
        config.api_key ||= ENV["TRUELIST_API_KEY"]
      end
    end
  end
end
