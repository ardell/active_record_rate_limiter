ActiveRecord::Schema.define do
  self.verbose = false

  create_table :rate_limited_events, force: true do |t|
    t.string :event_type, null: false
    t.timestamps null: false

    t.index [:event_type, :created_at]
  end
end

