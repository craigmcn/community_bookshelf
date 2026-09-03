require "test_helper"

class Api::V1::NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @moderator = users(:moderator)
    @admin = users(:admin)
  end

  test "no token is rejected" do
    get api_v1_notifications_url
    assert_response :unauthorized
  end

  test "index shows only the token owner's notifications" do
    Follow.create!(follower: @member, followed: @moderator)
    Follow.create!(follower: @admin, followed: @member)

    get api_v1_notifications_url, headers: auth_headers(@moderator)
    assert_response :success

    json = JSON.parse(response.body)["notifications"]
    assert_equal 1, json.size
    assert_equal @member.display_name, json.first["actor"]["display_name"]
    assert_equal "new_follower", json.first["notification_type"]
    assert_equal "user", json.first["target_type"]
    assert_equal @member.id, json.first["target_id"]
  end

  test "index is empty for a user with no notifications" do
    get api_v1_notifications_url, headers: auth_headers(@member)
    assert_response :success
    assert_equal [], JSON.parse(response.body)["notifications"]
  end

  test "update marks a notification read and returns it" do
    Follow.create!(follower: @member, followed: @moderator)
    notification = @moderator.notifications.last

    patch api_v1_notification_url(notification), headers: auth_headers(@moderator)
    assert_response :success

    json = JSON.parse(response.body)
    assert json["read_at"].present?
    assert notification.reload.read?
  end

  test "a user cannot mark another user's notification read" do
    Follow.create!(follower: @member, followed: @moderator)
    notification = @moderator.notifications.last

    patch api_v1_notification_url(notification), headers: auth_headers(@admin)
    assert_response :not_found
    assert_not notification.reload.read?
  end

  test "mark_all_read marks every unread notification read" do
    Follow.create!(follower: @member, followed: @moderator)
    Follow.create!(follower: @admin, followed: @moderator)

    patch mark_all_read_api_v1_notifications_url, headers: auth_headers(@moderator)
    assert_response :success

    assert_equal 2, JSON.parse(response.body)["marked_read"]
    assert_equal 0, @moderator.notifications.unread.count
  end

  test "a token without write:notifications cannot mark read" do
    Follow.create!(follower: @member, followed: @moderator)
    notification = @moderator.notifications.last

    patch api_v1_notification_url(notification), headers: auth_headers(@moderator, scopes: ["read:notifications"])
    assert_response :forbidden
  end

  test "a token without read:notifications cannot list" do
    get api_v1_notifications_url, headers: auth_headers(@member, scopes: ["write:notifications"])
    assert_response :forbidden
  end
end
