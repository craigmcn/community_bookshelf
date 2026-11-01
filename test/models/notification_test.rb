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

  test "a buddy read invite notifies the partner" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))

    notification = buddy_read.notification
    assert_equal users(:moderator), notification.recipient
    assert_equal users(:member), notification.actor
    assert notification.buddy_read_invite?
    assert_equal "#{users(:member).display_name} invited you to a buddy read of #{books(:one).title}", notification.message
    assert_equal "buddy_read", notification.target_type
    assert_equal buddy_read.id, notification.target_id
  end

  test "a buddy read message notifies the other participant, whichever side sends it" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))

    from_initiator = BuddyReadMessage.create!(buddy_read: buddy_read, user: users(:member), body: "Chapter 1 done!")
    from_partner = BuddyReadMessage.create!(buddy_read: buddy_read, user: users(:moderator), body: "Same here!")

    assert_equal users(:moderator), from_initiator.notification.recipient
    assert_equal users(:member), from_partner.notification.recipient
    assert from_initiator.notification.buddy_read_message?
    assert_equal "#{users(:member).display_name} sent a message in your buddy read of #{books(:one).title}", from_initiator.notification.message
    assert_equal "buddy_read", from_initiator.notification.target_type
    assert_equal buddy_read.id, from_initiator.notification.target_id
  end

  test "destroying a buddy read removes its invite and message notifications" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    BuddyReadMessage.create!(buddy_read: buddy_read, user: users(:member), body: "Chapter 1 done!")

    assert_difference "Notification.count", -2 do
      buddy_read.destroy
    end
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

  test "with_message_associations avoids N+1 queries across every nested notifiable type" do
    ReviewComment.create!(user: users(:moderator), reading: readings(:one), body: "Nice review!")
    ReviewComment.create!(user: users(:admin), reading: readings(:one), body: "Agreed!")

    club = Club.create!(name: "Sci-Fi Society", book: books(:two), created_by: users(:admin))
    club.club_memberships.create!(user: readings(:one).user)
    ClubPost.create!(club: club, user: users(:admin), body: "Excited to start!")
    ClubPost.create!(club: club, user: users(:admin), body: "Chapter 1 thoughts?")

    [users(:moderator), users(:admin)].each do |initiator|
      buddy_read = BuddyRead.create!(book: books(:two), initiator: initiator, partner: readings(:one).user)
      BuddyReadMessage.create!(buddy_read: buddy_read, user: initiator, body: "Ready to start?")
    end

    notifications = Notification.with_message_associations.where(recipient: readings(:one).user).to_a

    assert_no_queries do
      notifications.each(&:message)
    end
  end
end
