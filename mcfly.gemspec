$:.push File.expand_path("../lib", __FILE__)

require "mcfly/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mcfly"
  s.version     = Mcfly::VERSION
  s.authors     = ["Arman Bostani"]
  s.email       = ["arman.bostani@pnmac.com"]
  s.homepage    = "https://github.com/arman000/mcfly"
  s.summary     = %q{A database table versioning system.}
  s.description = s.summary
  s.files 	= `git ls-files`.split($\)

  s.require_paths = ["lib"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "pg"

  # FIXME: Delorean is added here for historical reasons.  It should
  # be removed as a dependency.
  s.add_dependency "delorean_lang"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
end
