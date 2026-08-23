require "test_helper"

class ReadingChallengesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @challenge = ReadingChallenge.create!(user: users(:member), year: 2026, goal: 20)
  end

  test "guest is redirected to sign in" do
    get reading_challenges_url
    assert_redirected_to sign_in_path
  end

  test "member can view their own challenges" do
    sign_in_as users(:member)
    get reading_challenges_url
    assert_response :success
  end

  test "member can create a challenge" do
    sign_in_as users(:member)
    assert_difference "ReadingChallenge.count" do
      post reading_challenges_url, params: {reading_challenge: {year: 2027, goal: 15}}
    end
    assert_redirected_to reading_challenges_url
  end

  test "member cannot create a duplicate-year challenge" do
    sign_in_as users(:member)
    assert_no_difference "ReadingChallenge.count" do
      post reading_challenges_url, params: {reading_challenge: {year: @challenge.year, goal: 15}}
    end
    assert_response :unprocessable_content
  end

  test "member can update their own challenge's goal" do
    sign_in_as users(:member)
    patch reading_challenge_url(@challenge), params: {reading_challenge: {goal: 30}}
    assert_redirected_to reading_challenges_url
    assert_equal 30, @challenge.reload.goal
  end

  test "member cannot update another user's challenge" do
    sign_in_as users(:moderator)
    patch reading_challenge_url(@challenge), params: {reading_challenge: {goal: 30}}
    assert_response :not_found
  end
end
