require "test_helper"

class NotificationsMailerTest < ActionMailer::TestCase
  test "digest includes each not-yet-digested notification" do
    Follow.create!(follower: users(:member), followed: users(:moderator))

    email = NotificationsMailer.digest(users(:moderator))

    assert_equal [users(:moderator).email], email.to
    assert_equal "Your Community Bookshelf digest", email.subject
    assert_match users(:member).display_name, email.html_part.body.to_s
    assert_match users(:member).display_name, email.text_part.body.to_s
  end

  test "digest is not sent when there are no notifications to send" do
    assert_emails 0 do
      NotificationsMailer.digest(users(:member)).deliver_now
    end
  end
end
