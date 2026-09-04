require "test_helper"

class Api::V1::ReviewCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
    @moderator = users(:moderator)
  end

  test "no token is rejected" do
    post api_v1_reading_review_comments_url(@reading), params: {review_comment: {body: "Nice!"}}
    assert_response :unauthorized
  end

  test "another user can comment on a public review" do
    assert_difference "@reading.review_comments.count" do
      post api_v1_reading_review_comments_url(@reading), params: {review_comment: {body: "Nice!"}}, headers: auth_headers(@moderator)
    end
    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "Nice!", json["body"]
    assert_equal @moderator.display_name, json["user"]["display_name"]
  end

  test "another user cannot comment on a private review" do
    @reading.update!(is_review_public: false)

    assert_no_difference "@reading.review_comments.count" do
      post api_v1_reading_review_comments_url(@reading), params: {review_comment: {body: "Nice!"}}, headers: auth_headers(@moderator)
    end
    assert_response :forbidden
  end

  test "comment author can delete their own comment" do
    comment = ReviewComment.create!(user: @moderator, reading: @reading, body: "Nice!")

    assert_difference "ReviewComment.count", -1 do
      delete api_v1_reading_review_comment_url(@reading, comment), headers: auth_headers(@moderator)
    end
    assert_response :no_content
  end

  test "another member cannot delete someone else's comment" do
    comment = ReviewComment.create!(user: @moderator, reading: @reading, body: "Nice!")
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)

    assert_no_difference "ReviewComment.count" do
      delete api_v1_reading_review_comment_url(@reading, comment), headers: auth_headers(other_member)
    end
    assert_response :forbidden
  end

  test "moderator can delete another member's comment" do
    author = User.create!(email: "author@example.com", password: User::DEFAULT_PASSWORD)
    comment = ReviewComment.create!(user: author, reading: @reading, body: "Nice!")

    assert_difference "ReviewComment.count", -1 do
      delete api_v1_reading_review_comment_url(@reading, comment), headers: auth_headers(@moderator)
    end
    assert_response :no_content
  end

  test "a token without write:review_comments cannot comment" do
    post api_v1_reading_review_comments_url(@reading), params: {review_comment: {body: "Nice!"}}, headers: auth_headers(@moderator, scopes: ["read:readings"])
    assert_response :forbidden
  end
end
