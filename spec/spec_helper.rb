require 'bundler/setup'
Bundler.setup

# Set up a test database
# NOTE: adapted from http://stackoverflow.com/questions/18543155/testing-a-gem-that-uses-activerecord-models
require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
load "#{File.dirname(__FILE__)}/schema.rb"

require 'active_record_rate_limiter'

RSpec.configure do |config|
  # So we don't get a ton of lock-* files from with_advisory_lock gem
  config.before { ENV['FLOCK_DIR'] = Dir.mktmpdir }
  config.after { FileUtils.remove_entry_secure ENV['FLOCK_DIR'] }
end

