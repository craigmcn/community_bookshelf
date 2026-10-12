require "test_helper"

class NotificationsMailerTest < ActionMailer::TestCase
  test "digest includes each notification passed in by id" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    notification = users(:moderator).notifications.last

    email = NotificationsMailer.digest(users(:moderator), [notification.id])

    assert_equal [users(:moderator).email], email.to
    assert_equal "Your Community Bookshelf digest", email.subject
    assert_match users(:member).display_name, email.html_part.body.to_s
    assert_match users(:member).display_name, email.text_part.body.to_s
  end

  test "digest renders review_comment and club_post messages without extra queries" do
    # Bullet only watches web requests, not mailers run from a job, so the
    # nested-preload guarantee is asserted directly here. Each round uses a
    # fresh book/reading/club so the test's query cache can't mask an N+1.
    recipient = users(:member)
    add_comment_and_post = ->(n) {
      book = Book.create!(title: "Book #{n}", author: "Author", added_by: users(:admin))
      reading = Reading.create!(user: recipient, book: book, status: :finished, review: "Loved it", is_review_public: true)
      ReviewComment.create!(user: users(:moderator), reading: reading, body: "Nice review!")
      club = Club.create!(name: "Club #{n}", book: book, created_by: users(:admin))
      club.club_memberships.create!(user: recipient)
      ClubPost.create!(club: club, user: users(:admin), body: "Excited to start!")
    }

    add_comment_and_post.call(1)
    one_each = digest_query_count(recipient)
    add_comment_and_post.call(2)

    assert_equal one_each, digest_query_count(recipient)
  end

  test "digest is not sent when there are no notification ids to send" do
    assert_emails 0 do
      NotificationsMailer.digest(users(:member), []).deliver_now
    end
  end

  private

  def digest_query_count(user)
    ids = user.notifications.ids
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      NotificationsMailer.digest(user, ids).message
    end
    count
  end
end
