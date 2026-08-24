require "test_helper"

class SendNotificationDigestsJobTest < ActiveJob::TestCase
  test "sends one digest per user with pending notifications and marks them digested" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    Follow.create!(follower: users(:member), followed: users(:admin))

    assert_enqueued_emails 2 do
      SendNotificationDigestsJob.perform_now
    end

    assert Notification.not_yet_digested.none?
  end

  test "does not send a digest when there are no notifications at all" do
    assert_no_enqueued_emails do
      SendNotificationDigestsJob.perform_now
    end
  end

  test "does not re-send a notification already included in a previous digest" do
    Follow.create!(follower: users(:member), followed: users(:moderator))

    assert_enqueued_emails 1 do
      SendNotificationDigestsJob.perform_now
    end

    assert_no_enqueued_emails do
      SendNotificationDigestsJob.perform_now
    end
  end
end
