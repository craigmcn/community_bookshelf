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

  # Regression test: perform_enqueued_jobs actually re-runs the mailer
  # method the way ActionMailer::MailDeliveryJob does in production, rather
  # than just checking a job was enqueued — that's the only way to catch a
  # digest that was queued but whose mailer body later renders empty (e.g.
  # because it re-derives its notifications from state the job already
  # mutated by the time the queued job runs).
  test "actually delivers the digest email once queued jobs run" do
    Follow.create!(follower: users(:member), followed: users(:moderator))

    perform_enqueued_jobs do
      SendNotificationDigestsJob.perform_now
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [users(:moderator).email], ActionMailer::Base.deliveries.last.to
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
