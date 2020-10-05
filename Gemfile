# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in mcfly.gemspec
gemspec

group :development, :test do
  group :cmit do
    gem 'cm_shared', git: 'https://gitlab.pnmac.com/cm_tech/cm_shared.git'
    # gem 'cm_shared', path: File.expand_path('../cm_shared', __dir__)
    # gem 'delorean_lang', path: File.expand_path('../delorean', __dir__)
  end
  gem 'brakeman'
  gem 'pry-rails'
  gem 'rspec-instafail', require: false
  gem 'simplecov'
end
