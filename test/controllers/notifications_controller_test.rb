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

  test "update on a buddy read invite redirects to the buddy read" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))

    sign_in_as users(:moderator)
    patch notification_url(buddy_read.notification)

    assert_redirected_to buddy_read_url(buddy_read)
  end

  test "update on a buddy read message redirects to its buddy read" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    message = BuddyReadMessage.create!(buddy_read: buddy_read, user: users(:member), body: "Chapter 1 done!")

    sign_in_as users(:moderator)
    patch notification_url(message.notification)

    assert_redirected_to buddy_read_url(buddy_read)
  end

  test "a user cannot mark another user's notification read" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    notification = users(:moderator).notifications.last

    sign_in_as users(:admin)
    patch notification_url(notification)

    assert_response :not_found
    assert_not notification.reload.read?
  end

  test "index and the navbar dropdown render without N+1ing on nested notifiable associations" do
    # Two of each type, not one — Bullet only flags a lazy load repeated
    # across records from the same query, so one per type wouldn't catch it.
    ReviewComment.create!(user: users(:moderator), reading: readings(:one), body: "Nice review!")
    ReviewComment.create!(user: users(:admin), reading: readings(:one), body: "Agreed!")

    club = Club.create!(name: "Sci-Fi Society", book: books(:two), created_by: users(:moderator))
    club.club_memberships.create!(user: readings(:one).user)
    ClubPost.create!(club: club, user: users(:moderator), body: "Excited to start!")
    ClubPost.create!(club: club, user: users(:moderator), body: "Chapter 1 thoughts?")

    [users(:moderator), users(:admin)].each do |initiator|
      buddy_read = BuddyRead.create!(book: books(:two), initiator: initiator, partner: readings(:one).user)
      BuddyReadMessage.create!(buddy_read: buddy_read, user: initiator, body: "Ready to start?")
    end

    sign_in_as readings(:one).user
    get notifications_url

    assert_response :success
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
