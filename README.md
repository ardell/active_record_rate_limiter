active_record_rate_limiter
==========================

Installation
------------

1. Add `gem 'active_record_rate_limiter', git: 'git://github.com/ardell/active_record_rate_limiter.git'` to your Gemfile
1. Run `bundle install`
1. Run `rails g active_record_rate_limiter:install`
1. Run `rake db:migrate`


Add a Limiter
-------------

A simple rate limiter:

```
# Limits actions to 10 per second.
class TenTimesPerSecondLimiter < ActiveRecordRateLimiter::Limiter
  event_type 'TenTimesPerSecond'
  limit 10, since: proc { 1.second.ago }
end
```

A more complex rate limiter with multiple rules for a single event type:

```
# Limits actions to 10 per second AND 100 per day. E.g. if there have already
# been 100 actions in the past 24 hours, `limited?` will return true no matter
# how few actions have occurred in the past second.
class ComplexLimiter < ActiveRecordRateLimiter::Limiter
  event_type 'Complex'
  limit 10,  since: proc { 1.second.ago }
  limit 100, since: proc { 1.day.ago }
end
```

A custom handler when the limit is hit (default is to sleep for 0.1 seconds)...

```
class ComplexLimiter < ActiveRecordRateLimiter::Limiter
  # Custom handler for on_limit
  # NOTEs:
  # - it's a class method
  # - it's defined before calling `limit`
  def self.sleep_longer
    sleep(10)
  end

  event_type 'CustomHandler'
  limit 1, since: proc { 10.seconds.ago }, on_limit: :sleep_longer
end
```


Record an Event
---------------

`TenTimesPerSecondLimiter.track`


Check Rate Limit
----------------

`TenTimesPerSecondRateLimiter.limited?`


Get Events
----------

To get a raw relation of all the events as an ActiveRecord relation:

`TenTimesPerSecondRateLimiter.events`

To simply get the total number of events matching the given event type:

`TenTimesPerSecondRateLimiter.events.count`


