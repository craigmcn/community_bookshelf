require "test_helper"

class Api::V1::ReadingChallengesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @challenge = ReadingChallenge.create!(user: @member, year: 2026, goal: 20)
  end

  test "no token is rejected" do
    get api_v1_reading_challenges_url
    assert_response :unauthorized
  end

  test "valid token lists only the token owner's challenges" do
    ReadingChallenge.create!(user: users(:moderator), year: 2026, goal: 10)

    get api_v1_reading_challenges_url, headers: auth_headers(@member)
    assert_response :success
    ids = JSON.parse(response.body)["reading_challenges"].pluck("id")
    assert_equal [@challenge.id], ids
  end

  test "index includes computed progress fields on each challenge" do
    ReadingChallenge.create!(user: @member, year: 2027, goal: 5)

    get api_v1_reading_challenges_url, headers: auth_headers(@member)
    challenge_json = JSON.parse(response.body)["reading_challenges"].find { |c| c["id"] == @challenge.id }
    assert_equal 0, challenge_json["books_finished_count"]
    assert_equal 0, challenge_json["progress_percent"]
    assert_equal false, challenge_json["completed"]
  end

  test "member can create a challenge" do
    assert_difference "ReadingChallenge.count" do
      post api_v1_reading_challenges_url, params: {reading_challenge: {year: 2028, goal: 15}}, headers: auth_headers(@member)
    end
    assert_response :created
    assert_equal 15, JSON.parse(response.body)["goal"]
  end

  test "member cannot create a duplicate-year challenge" do
    assert_no_difference "ReadingChallenge.count" do
      post api_v1_reading_challenges_url, params: {reading_challenge: {year: @challenge.year, goal: 15}}, headers: auth_headers(@member)
    end
    assert_response :unprocessable_content
    assert JSON.parse(response.body)["errors"].present?
  end

  test "member can update their own challenge's goal" do
    patch api_v1_reading_challenge_url(@challenge), params: {reading_challenge: {goal: 30}}, headers: auth_headers(@member)
    assert_response :success
    assert_equal 30, @challenge.reload.goal
  end

  test "update ignores a submitted year and leaves it unchanged" do
    original_year = @challenge.year
    patch api_v1_reading_challenge_url(@challenge), params: {reading_challenge: {year: 1999, goal: 30}}, headers: auth_headers(@member)
    assert_response :success
    assert_equal original_year, @challenge.reload.year
  end

  test "member cannot update another user's challenge" do
    patch api_v1_reading_challenge_url(@challenge), params: {reading_challenge: {goal: 30}}, headers: auth_headers(users(:moderator))
    assert_response :not_found
    assert_not_equal 30, @challenge.reload.goal
  end

  test "a read:reading_challenges-only token can list challenges" do
    get api_v1_reading_challenges_url, headers: auth_headers(@member, scopes: ["read:reading_challenges"])
    assert_response :success
  end

  test "a read:reading_challenges-only token cannot create a challenge" do
    assert_no_difference "ReadingChallenge.count" do
      post api_v1_reading_challenges_url, params: {reading_challenge: {year: 2028, goal: 15}}, headers: auth_headers(@member, scopes: ["read:reading_challenges"])
    end
    assert_response :forbidden
  end

  test "a write:reading_challenges-only token cannot list challenges" do
    get api_v1_reading_challenges_url, headers: auth_headers(@member, scopes: ["write:reading_challenges"])
    assert_response :forbidden
  end
end
