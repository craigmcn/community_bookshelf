require "test_helper"

class ReviewLikeTest < ActiveSupport::TestCase
  test "valid with a user and reading" do
    assert ReviewLike.new(user: users(:moderator), reading: readings(:one)).valid?
  end

  test "invalid with a duplicate like from the same user" do
    ReviewLike.create!(user: users(:moderator), reading: readings(:one))
    duplicate = ReviewLike.new(user: users(:moderator), reading: readings(:one))
    assert_not duplicate.valid?
  end
end
