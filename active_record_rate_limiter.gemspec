$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_record_rate_limiter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_record_rate_limiter"
  s.version     = ActiveRecordRateLimiter::VERSION
  s.authors     = ["Jason Ardell"]
  s.email       = ["ardell@gmail.com"]
  s.homepage    = "https://github.com/ardell/active_record_rate_limiter"
  s.summary     = "A simple rate limiter backed by ActiveRecord."
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 5", "< 7"
  s.add_dependency "with_advisory_lock", "~> 4.0.0"

  s.add_development_dependency "sqlite3", "~> 1.4"
  s.add_development_dependency "rspec"
end

