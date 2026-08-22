require "test_helper"

class ReviewLikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "guest is redirected to sign in" do
    post reading_review_like_url(@reading)
    assert_redirected_to sign_in_path
  end

  test "member can like a public review" do
    sign_in_as users(:moderator)
    post reading_review_like_url(@reading)

    assert_redirected_to reading_url(@reading)
    assert @reading.review_likes.exists?(user: users(:moderator))
  end

  test "member cannot like a private review" do
    @reading.update!(is_review_public: false)
    sign_in_as users(:moderator)
    post reading_review_like_url(@reading)

    assert_not @reading.review_likes.exists?(user: users(:moderator))
  end

  test "member can unlike" do
    ReviewLike.create!(user: users(:moderator), reading: @reading)
    sign_in_as users(:moderator)

    delete reading_review_like_url(@reading)

    assert_redirected_to reading_url(@reading)
    assert_not @reading.review_likes.exists?(user: users(:moderator))
  end

  test "unliking twice is idempotent" do
    sign_in_as users(:moderator)

    delete reading_review_like_url(@reading)

    assert_redirected_to reading_url(@reading)
    assert_not @reading.review_likes.exists?(user: users(:moderator))
  end
end
