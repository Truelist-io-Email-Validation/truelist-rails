# frozen_string_literal: true

module Truelist
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Creates a Truelist initializer in config/initializers'

      def create_initializer
        template 'initializer.rb', 'config/initializers/truelist.rb'
      end

      def show_instructions
        say ''
        say 'Truelist initializer created at config/initializers/truelist.rb', :green
        say ''
        say 'Next steps:'
        say '  1. Set your API key via TRUELIST_API_KEY environment variable'
        say '     or uncomment the api_key line in the initializer'
        say '  2. Add `validates :email, deliverable: true` to your models'
        say ''
      end
    end
  end
end
