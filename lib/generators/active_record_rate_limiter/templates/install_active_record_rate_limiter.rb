# frozen_string_literal: true
class InstallActiveRecordRateLimiter < ActiveRecord::Migration

  def change
    create_table :rate_limited_events do |t|
      t.string :event_type, null: false
      t.timestamps null: false

      t.index [:event_type, :created_at]
    end
  end

end

