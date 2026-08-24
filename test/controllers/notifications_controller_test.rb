require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get notifications_url
    assert_redirected_to sign_in_path
  end

  test "index shows only the current user's notifications" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    Follow.create!(follower: users(:admin), followed: users(:member))

    sign_in_as users(:moderator)
    get notifications_url

    assert_response :success
    assert_includes @response.body, users(:member).display_name
  end

  test "index is empty for a user with no notifications" do
    sign_in_as users(:member)
    get notifications_url
    assert_response :success
  end

  test "update marks a notification read and redirects to its target" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    notification = users(:moderator).notifications.last

    sign_in_as users(:moderator)
    patch notification_url(notification)

    assert_redirected_to user_url(users(:member))
    assert notification.reload.read?
  end

  test "a user cannot mark another user's notification read" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    notification = users(:moderator).notifications.last

    sign_in_as users(:admin)
    patch notification_url(notification)

    assert_response :not_found
    assert_not notification.reload.read?
  end

  test "mark_all_read marks every unread notification read" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    Follow.create!(follower: users(:admin), followed: users(:moderator))

    sign_in_as users(:moderator)
    patch mark_all_read_notifications_url

    assert_redirected_to notifications_url
    assert_equal 0, users(:moderator).notifications.unread.count
  end
end
