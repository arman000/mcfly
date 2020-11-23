# frozen_string_literal: true

require_relative 'lib/mcfly/version'

files = Dir[
  'lib/**/*',
  'Gemfile',
  'mcfly.gemspec',
  'MIT-LICENSE',
  'Rakefile',
  'README.md',
]

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'mcfly'
  s.version     = Mcfly::VERSION
  s.authors     = ['Arman Bostani']
  s.email       = ['arman.bostani@pnmac.com']
  s.homepage    = 'https://github.com/arman000/mcfly'
  s.summary     = 'A database table versioning system.'
  s.description = s.summary
  s.files       = files
  s.licenses    = ['MIT']

  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.5.7'

  s.add_dependency 'delorean_lang'
  s.add_dependency 'pg'

  s.add_development_dependency 'rspec-rails'
end
