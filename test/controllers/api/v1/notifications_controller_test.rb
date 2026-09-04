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

  test "index renders review_comment and club_post notifications without an N+1" do
    # Two of each type, not one — Bullet's N+1 detector only flags a
    # repeated lazy-load pattern within a request, so a single notification
    # of a type wouldn't have caught the missing preload this test guards.
    reading_one = Reading.create!(user: @member, book: books(:one), status: :finished, review: "Loved it", is_review_public: true)
    reading_two = Reading.create!(user: @member, book: books(:two), status: :finished, review: "So good", is_review_public: true)
    ReviewComment.create!(reading: reading_one, user: @moderator, body: "Nice review!")
    ReviewComment.create!(reading: reading_two, user: @admin, body: "Agreed!")

    club_one = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: @member)
    club_two = Club.create!(name: "Classics Club", book: books(:two), created_by: @member)
    club_one.club_memberships.create!(user: @moderator)
    club_two.club_memberships.create!(user: @admin)
    ClubPost.create!(club: club_one, user: @moderator, body: "Hi everyone!")
    ClubPost.create!(club: club_two, user: @admin, body: "Hi from here too!")

    get api_v1_notifications_url, headers: auth_headers(@member)
    assert_response :success

    json = JSON.parse(response.body)["notifications"]
    review_comment_json = json.find { |n| n["target_id"] == reading_one.id }
    assert_equal "reading", review_comment_json["target_type"]
    assert_includes review_comment_json["message"], reading_one.book.title

    club_post_json = json.find { |n| n["target_id"] == club_one.id }
    assert_equal "club", club_post_json["target_type"]
    assert_includes club_post_json["message"], club_one.name
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
