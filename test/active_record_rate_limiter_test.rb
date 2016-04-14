require 'test_helper'

class ActiveRecordRateLimiterTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, ActiveRecordRateLimiter
  end
end
