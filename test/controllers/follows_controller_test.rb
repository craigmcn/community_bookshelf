require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    post user_follow_url(users(:moderator))
    assert_redirected_to sign_in_path
  end

  test "member can follow another member" do
    sign_in_as users(:member)
    post user_follow_url(users(:moderator))

    assert_redirected_to user_url(users(:moderator))
    assert users(:member).reload.following?(users(:moderator))
  end

  test "member cannot follow themselves" do
    sign_in_as users(:member)
    post user_follow_url(users(:member))

    assert_not users(:member).reload.following?(users(:member))
  end

  test "member can unfollow" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    sign_in_as users(:member)

    delete user_follow_url(users(:moderator))

    assert_redirected_to user_url(users(:moderator))
    assert_not users(:member).reload.following?(users(:moderator))
  end
end
