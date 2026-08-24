require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "a new follow creates a notification for the followed user" do
    assert_difference "Notification.count", 1 do
      Follow.create!(follower: users(:member), followed: users(:moderator))
    end

    notification = Notification.last
    assert_equal users(:moderator), notification.recipient
    assert_equal users(:member), notification.actor
    assert notification.new_follower?
    assert_not notification.read?
  end

  test "unfollowing destroys the associated notification" do
    follow = Follow.create!(follower: users(:member), followed: users(:moderator))

    assert_difference "Notification.count", -1 do
      follow.destroy
    end
  end

  test "commenting on someone else's review creates a notification for the reading's owner" do
    assert_difference "Notification.count", 1 do
      ReviewComment.create!(user: users(:moderator), reading: readings(:one), body: "Nice review!")
    end

    notification = Notification.last
    assert_equal readings(:one).user, notification.recipient
    assert_equal users(:moderator), notification.actor
    assert notification.review_comment?
  end

  test "commenting on your own review does not create a notification" do
    assert_no_difference "Notification.count" do
      ReviewComment.create!(user: readings(:one).user, reading: readings(:one), body: "My own thoughts")
    end
  end

  test "a club post notifies every other member, but not the poster" do
    club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
    club.club_memberships.create!(user: users(:moderator))
    club.club_memberships.create!(user: users(:admin))

    assert_difference "Notification.count", 2 do
      ClubPost.create!(club: club, user: users(:member), body: "Excited to start!")
    end

    recipients = Notification.last(2).map(&:recipient)
    assert_equal [users(:moderator), users(:admin)].to_set, recipients.to_set
    assert Notification.last(2).all?(&:club_post?)
  end

  test "mark_read! sets read_at only once" do
    follow = Follow.create!(follower: users(:member), followed: users(:moderator))
    notification = follow.notification

    notification.mark_read!
    read_at = notification.read_at
    assert_not_nil read_at

    notification.mark_read!
    assert_equal read_at, notification.reload.read_at
  end

  test "message describes each notification type" do
    follow = Follow.create!(follower: users(:member), followed: users(:moderator))
    assert_equal "#{users(:member).display_name} started following you", follow.notification.message
  end
end
