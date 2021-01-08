require 'active_record_rate_limiter/models/rate_limited_event'
require 'with_advisory_lock'

module ActiveRecordRateLimiter
  class Limiter
    def self.event_type(event_type)
      @_event_type = event_type
    end

    def self.limit(max_events, options)
      raise MaxEventsArgumentError if !max_events || max_events < 1

      unless options.key?(:since) && options[:since].respond_to?(:call)
        raise SinceArgumentError
      end
      unless options[:since].call.is_a?(Time)
        raise SinceArgumentError
      end

      on_limit_handler = options[:on_limit] || :sleep
      unless self.respond_to?(on_limit_handler)
        raise OnLimitArgumentError
      end

      @_rules ||= []
      @_rules << [
        max_events,
        options[:since],
        on_limit_handler,
      ]
    end

    # Check whether we're limited, wait if necessary, then record that the
    # thing happened.
    def self.track
      raise EventTypeNotSetError unless @_event_type

      # Delete old events
      if _should_delete_old_events
        ActiveRecordRateLimiter::Models::RateLimitedEvent
          .where('created_at < ?', 7.days.ago)
          .delete_all
      end

      # Lock the db table so we don't get race conditions
      lock_name = 'ActiveRecordRateLimiter'
      ActiveRecordRateLimiter::Models::RateLimitedEvent.with_advisory_lock(lock_name) do
        # If we're limited, call on_limit handler
        while (on_limit_handler = limited?)
          self.send(on_limit_handler)
        end

        # Save the new event
        self.increment
      end
    end

    # Blindly increment the count of things that happened. This is useful if
    # you are using `.limited?` independently of `.track`, i.e. when `on_limit`
    # is a no-op.
    def self.increment
      ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
        event_type: @_event_type
      })
    end

    def self.limited?
      @_rules.map do |rule|
        max_events, since_proc, on_limit = rule
        num_events = ActiveRecordRateLimiter::Models::RateLimitedEvent
          .where(event_type: @_event_type)
          .where('created_at >= ?', since_proc.call)
          .count
        (num_events >= max_events) ? on_limit : nil
      end.compact.first
    end

    def self.events
      ActiveRecordRateLimiter::Models::RateLimitedEvent
        .where(event_type: @_event_type)
    end

    def self.sleep
      Kernel.sleep(0.1)
    end

    # NOTE: only public for testing
    def self._should_delete_old_events
      rand(0..1000) == 0
    end

    # NOTE: only public for testing
    def self._event_type
      @_event_type
    end

    # NOTE: only public for testing
    def self._rules
      @_rules
    end
  end

  class MaxEventsArgumentError < ArgumentError; end
  class SinceArgumentError < ArgumentError; end
  class OnLimitArgumentError < StandardError; end
  class EventTypeNotSetError < StandardError; end
end

