require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "invalid without an action" do
    reading = Reading.create!(user: users(:member), book: books(:two), status: :want_to_read)
    assert_not Activity.new(user: users(:member), reading: reading).valid?
  end

  test "description reflects the action" do
    reading = Reading.create!(user: users(:member), book: books(:two), status: :want_to_read)
    activity = reading.activities.added_book.first
    assert_equal "added #{books(:two).title} to their shelf", activity.description
  end
end
