require "test_helper"

class Api::V1::FollowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @moderator = users(:moderator)
  end

  test "no token is rejected" do
    post api_v1_user_follow_url(@moderator)
    assert_response :unauthorized
  end

  test "member can follow another member" do
    assert_difference "Follow.count" do
      post api_v1_user_follow_url(@moderator), headers: auth_headers(@member)
    end
    assert_response :created
    assert @member.reload.following?(@moderator)
  end

  test "member cannot follow themselves" do
    assert_no_difference "Follow.count" do
      post api_v1_user_follow_url(@member), headers: auth_headers(@member)
    end
    assert_response :forbidden
  end

  test "following someone already followed returns 422" do
    Follow.create!(follower: @member, followed: @moderator)

    assert_no_difference "Follow.count" do
      post api_v1_user_follow_url(@moderator), headers: auth_headers(@member)
    end
    assert_response :unprocessable_content
    assert JSON.parse(response.body)["errors"].present?
  end

  test "member can unfollow" do
    Follow.create!(follower: @member, followed: @moderator)

    assert_difference "Follow.count", -1 do
      delete api_v1_user_follow_url(@moderator), headers: auth_headers(@member)
    end
    assert_response :no_content
    assert_not @member.reload.following?(@moderator)
  end

  test "unfollowing twice is idempotent" do
    delete api_v1_user_follow_url(@moderator), headers: auth_headers(@member)
    assert_response :no_content

    assert_no_difference "Follow.count" do
      delete api_v1_user_follow_url(@moderator), headers: auth_headers(@member)
    end
    assert_response :no_content
  end

  test "a write:follows-only token can follow and unfollow" do
    post api_v1_user_follow_url(@moderator), headers: auth_headers(@member, scopes: ["write:follows"])
    assert_response :created

    delete api_v1_user_follow_url(@moderator), headers: auth_headers(@member, scopes: ["write:follows"])
    assert_response :no_content
  end

  test "a token without write:follows cannot follow" do
    post api_v1_user_follow_url(@moderator), headers: auth_headers(@member, scopes: ["read:books"])
    assert_response :forbidden
  end
end
