# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ActiveRecordRateLimiter::Limiter do

  before(:each) do
    ActiveRecordRateLimiter::Models::RateLimitedEvent.destroy_all
  end

  let(:event_type) { 'FivePerDay' }
  let(:max_events) { 5 }
  let(:since) do proc { 1.day.ago } end
  let(:on_limit) { :custom_on_limit_handler }
  let(:limiter) do
    limiter = Class.new(ActiveRecordRateLimiter::Limiter)
    limiter.event_type event_type
    allow(limiter).to receive(on_limit)
    limiter.limit max_events, since: since, on_limit: on_limit
    limiter
  end

  describe 'self.limit' do
    it 'sets the max number of events per time period' do
      expect(limiter._rules.first[0]).to eq(5)
    end

    it 'sets the time start proc to the value in since' do
      expect(limiter._rules.first[1]).to eq(since)
    end

    it 'sets on_limit to the value in on_limit' do
      expect(limiter._rules.first[2]).to eq(on_limit)
    end

    [ nil, -1, 0 ].each do |value|
      it "raises an error if max events is invalid (#{value.inspect})" do
        expect { limiter.limit value, since: since }
          .to raise_error(ActiveRecordRateLimiter::MaxEventsArgumentError)
      end
    end

    it "raises an error if 'since' is not a proc" do
      expect { limiter.limit 5, since: 1 }
        .to raise_error(ActiveRecordRateLimiter::SinceArgumentError)
    end

    it "raises an error if 'since' proc does not return a Time object" do
      expect { limiter.limit 5, since: proc { 1 } }
        .to raise_error(ActiveRecordRateLimiter::SinceArgumentError)
    end

    it "raises an error if the limiter does not respond to 'on_limit'" do
      l = Class.new(ActiveRecordRateLimiter::Limiter)
      expect do
        l.limit 1, since: proc { 1.day.ago}, on_limit: :some_undeclared_method
      end.to raise_error(ActiveRecordRateLimiter::OnLimitArgumentError)
    end
  end

  describe 'self.event_type' do
    it 'sets the event_type' do
      expect(limiter._event_type).to eq(event_type)
    end
  end

  describe 'track' do
    it 'raises an error if event_type is not defined' do
      l = Class.new(ActiveRecordRateLimiter::Limiter)
      expect { l.track }
        .to raise_error(ActiveRecordRateLimiter::EventTypeNotSetError)
    end

    it 'increments the count of events' do
      expect(limiter).to receive(:increment)
      limiter.track
    end

    it 'deletes a rate_limited_events record older than 7 days' do
      old_event = ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
        event_type: 'Foo',
        created_at: 10.days.ago,
      })

      allow(ActiveRecordRateLimiter::Limiter)
        .to receive(:_should_delete_old_events)
        .and_return(true)
      limiter.track
      actual = ActiveRecordRateLimiter::Models::RateLimitedEvent.exists?(old_event.id)
      expect(actual).to be_falsy
    end

    it 'calls sleep by default on_limit' do
      ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
        event_type: event_type,
        created_at: Time.now,
      })

      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type event_type
      limiter.limit 1, since: proc { 1.second.ago }
      expect(limiter).to receive(:sleep) { sleep(1) }
      limiter.track
    end

    it 'calls on_limit handler when limit is hit' do
      ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
        event_type: event_type,
        created_at: Time.now,
      })

      limiter = Class.new(ActiveRecordRateLimiter::Limiter)
      limiter.event_type event_type
      expect(limiter).to receive(:custom_on_limit_handler) { sleep(1) }
      limiter.limit 1, since: proc { 1.second.ago }, on_limit: :custom_on_limit_handler

      limiter.track
    end
  end

  describe 'self.increment' do
    it 'adds a new record to the rate_limited_events table' do
      expect { limiter.increment }.to change {
        ActiveRecordRateLimiter::Models::RateLimitedEvent.count
      }.by(1)
    end
  end

  describe 'self.limited?' do
    it 'returns true if a single rule is at quota' do
      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type 'OnePerDayLimiter'
      l.limit 1, since: proc { 1.day.ago }
      l.track
      expect(l.limited?).to be_truthy
    end

    it 'returns true of one out of two rules is at quota' do
      event_type = 'ComplexLimiter'
      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type event_type
      l.limit 10, since: proc { 1.day.ago }
      l.limit 1, since: proc { 1.hour.ago }
      l.track
      expect(l.limited?).to be_truthy
    end

    it 'returns true of one out of two rules is at quota' do
      event_type = 'ComplexLimiter'
      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type event_type
      l.limit 1, since: proc { 1.day.ago }
      l.limit 10, since: proc { 1.hour.ago }

      ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
        event_type: event_type,
        created_at: 6.hours.ago,
      })

      expect(l.limited?).to be_truthy
    end

    it 'returns false if no rules are at quota' do
      event_type = 'ComplexLimiter'
      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type event_type
      l.limit 100, since: proc { 1.day.ago }
      l.limit 10, since: proc { 1.hour.ago }
      l.track
      expect(l.limited?).to be_falsy
    end

    it 'does not include other event types' do
      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type 'OnePerDayLimiter'
      l.limit 1, since: proc { 1.day.ago }

      ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
        event_type: 'SomeOtherLimiter',
        created_at: 6.hours.ago,
      })

      expect(l.limited?).to be_falsy
    end
  end

  describe 'self.events' do
    it 'includes all events matching the event_type' do
      expected_events = 5.times.collect do
        ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
          event_type: event_type,
          created_at: 6.hours.ago,
        })
      end

      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type event_type

      expect(l.events).to match_array(expected_events)
    end

    it 'does not include events for another event_type' do
      other_event = ActiveRecordRateLimiter::Models::RateLimitedEvent.create({
        event_type: 'SomeOtherEventType',
        created_at: 6.hours.ago,
      })

      l = Class.new(ActiveRecordRateLimiter::Limiter)
      l.event_type event_type

      expect(l.events).not_to include(other_event)
    end
  end

end

