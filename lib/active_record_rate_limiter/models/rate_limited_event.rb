require 'active_record'

module ActiveRecordRateLimiter
  module Models
    class RateLimitedEvent < ActiveRecord::Base
      validates :event_type, presence: true
    end
  end
end

