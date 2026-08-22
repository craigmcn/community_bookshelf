require "test_helper"

class FollowTest < ActiveSupport::TestCase
  test "valid with distinct follower and followed" do
    follow = Follow.new(follower: users(:member), followed: users(:moderator))
    assert follow.valid?
  end

  test "invalid following yourself" do
    follow = Follow.new(follower: users(:member), followed: users(:member))
    assert_not follow.valid?
  end

  test "invalid with a duplicate follow" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    duplicate = Follow.new(follower: users(:member), followed: users(:moderator))
    assert_not duplicate.valid?
  end

  test "User#following? reflects an active follow" do
    member = users(:member)
    moderator = users(:moderator)
    assert_not member.following?(moderator)

    Follow.create!(follower: member, followed: moderator)
    assert member.reload.following?(moderator)
  end
end
