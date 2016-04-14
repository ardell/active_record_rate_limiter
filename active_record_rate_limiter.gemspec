$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_record_rate_limiter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_record_rate_limiter"
  s.version     = ActiveRecordRateLimiter::VERSION
  s.authors     = ["Jason Ardell"]
  s.email       = ["ardell@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of ActiveRecordRateLimiter."
  s.description = "TODO: Description of ActiveRecordRateLimiter."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.6"

  s.add_development_dependency "sqlite3"
end
