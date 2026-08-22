require "test_helper"

class ReviewCommentTest < ActiveSupport::TestCase
  test "valid with a user, reading, and body" do
    assert ReviewComment.new(user: users(:moderator), reading: readings(:one), body: "Nice review!").valid?
  end

  test "invalid without a body" do
    assert_not ReviewComment.new(user: users(:moderator), reading: readings(:one)).valid?
  end

  test "invalid with a body over 1000 characters" do
    comment = ReviewComment.new(user: users(:moderator), reading: readings(:one), body: "a" * 1001)
    assert_not comment.valid?
  end
end
