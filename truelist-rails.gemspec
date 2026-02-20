# frozen_string_literal: true

require_relative 'lib/truelist/version'

Gem::Specification.new do |spec|
  spec.name = 'truelist-rails'
  spec.version = Truelist::VERSION
  spec.authors = ['Truelist']
  spec.email = ['support@truelist.io']

  spec.summary = 'Email validation for Rails, powered by Truelist.io'
  spec.description = 'Rails integration for the Truelist.io email validation API. ' \
                     'Validate email deliverability with a simple ActiveModel validator.'
  spec.homepage = 'https://github.com/Truelist-io-Email-Validation/truelist-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    Dir['{lib}/**/*', 'LICENSE', 'README.md']
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel', '>= 7.0'
  spec.add_dependency 'activesupport', '>= 7.0'
end
