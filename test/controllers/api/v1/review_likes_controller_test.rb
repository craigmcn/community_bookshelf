require "test_helper"

class Api::V1::ReviewLikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
    @moderator = users(:moderator)
  end

  test "no token is rejected" do
    post api_v1_reading_review_like_url(@reading)
    assert_response :unauthorized
  end

  test "member can like a public review" do
    assert_difference "@reading.review_likes.count" do
      post api_v1_reading_review_like_url(@reading), headers: auth_headers(@moderator)
    end
    assert_response :created
    assert_equal @moderator.id, JSON.parse(response.body)["user_id"]
  end

  test "member cannot like a private review" do
    @reading.update!(is_review_public: false)

    assert_no_difference "@reading.review_likes.count" do
      post api_v1_reading_review_like_url(@reading), headers: auth_headers(@moderator)
    end
    assert_response :forbidden
  end

  test "member can unlike" do
    ReviewLike.create!(user: @moderator, reading: @reading)

    assert_difference "@reading.review_likes.count", -1 do
      delete api_v1_reading_review_like_url(@reading), headers: auth_headers(@moderator)
    end
    assert_response :no_content
  end

  test "unliking twice is idempotent" do
    delete api_v1_reading_review_like_url(@reading), headers: auth_headers(@moderator)
    assert_response :no_content

    assert_no_difference "@reading.review_likes.count" do
      delete api_v1_reading_review_like_url(@reading), headers: auth_headers(@moderator)
    end
    assert_response :no_content
  end

  test "a token without write:review_likes cannot like" do
    post api_v1_reading_review_like_url(@reading), headers: auth_headers(@moderator, scopes: ["read:readings"])
    assert_response :forbidden
  end
end
