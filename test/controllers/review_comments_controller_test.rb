require "test_helper"

class ReviewCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "guest is redirected to sign in" do
    post reading_review_comments_url(@reading), params: {review_comment: {body: "Nice!"}}
    assert_redirected_to sign_in_path
  end

  test "member can comment on a public review" do
    sign_in_as users(:moderator)
    post reading_review_comments_url(@reading), params: {review_comment: {body: "Nice!"}}

    assert_redirected_to reading_url(@reading)
    assert @reading.review_comments.exists?(user: users(:moderator), body: "Nice!")
  end

  test "member cannot comment on a private review" do
    @reading.update!(is_review_public: false)
    sign_in_as users(:moderator)
    post reading_review_comments_url(@reading), params: {review_comment: {body: "Nice!"}}

    assert_not @reading.review_comments.exists?(user: users(:moderator))
  end

  test "comment author can delete their own comment" do
    comment = ReviewComment.create!(user: users(:moderator), reading: @reading, body: "Nice!")
    sign_in_as users(:moderator)

    delete reading_review_comment_url(@reading, comment)

    assert_redirected_to reading_url(@reading)
    assert_not ReviewComment.exists?(comment.id)
  end

  test "another member cannot delete someone else's comment" do
    comment = ReviewComment.create!(user: users(:moderator), reading: @reading, body: "Nice!")
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    sign_in_as other_member

    delete reading_review_comment_url(@reading, comment)

    assert ReviewComment.exists?(comment.id)
  end

  test "moderator can delete another member's comment" do
    author = User.create!(email: "author@example.com", password: User::DEFAULT_PASSWORD)
    comment = ReviewComment.create!(user: author, reading: @reading, body: "Nice!")
    sign_in_as users(:moderator)

    delete reading_review_comment_url(@reading, comment)

    assert_not ReviewComment.exists?(comment.id)
  end
end
