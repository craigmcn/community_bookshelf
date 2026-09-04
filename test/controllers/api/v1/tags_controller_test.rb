require "test_helper"

class Api::V1::TagsControllerTest < ActionDispatch::IntegrationTest
  test "no token is rejected" do
    get api_v1_tags_url
    assert_response :unauthorized
  end

  test "valid token lists all tags" do
    get api_v1_tags_url, headers: auth_headers(users(:member))
    assert_response :success
    assert_equal Tag.count, JSON.parse(response.body)["tags"].size
  end

  test "filters by category" do
    mood_tag = Tag.create!(name: "cozy", category: "mood")

    get api_v1_tags_url, params: {category: "mood"}, headers: auth_headers(users(:member))
    assert_response :success

    json = JSON.parse(response.body)["tags"]
    assert_equal [mood_tag.id], json.pluck("id")
  end

  test "an unrecognized category is ignored, returning all tags" do
    get api_v1_tags_url, params: {category: "bogus"}, headers: auth_headers(users(:member))
    assert_response :success
    assert_equal Tag.count, JSON.parse(response.body)["tags"].size
  end

  test "a token without read:tags is rejected" do
    get api_v1_tags_url, headers: auth_headers(users(:member), scopes: ["read:books"])
    assert_response :forbidden
  end
end
