require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get feed_url
    assert_redirected_to sign_in_path
  end

  test "feed shows activity from followed users, not others" do
    Follow.create!(follower: users(:member), followed: users(:moderator))
    followed_reading = Reading.create!(user: users(:moderator), book: books(:two), status: :reading)
    Reading.create!(user: users(:admin), book: books(:one), status: :reading)

    sign_in_as users(:member)
    get feed_url

    assert_response :success
    assert_select "a", text: users(:moderator).display_name
    assert_select "a", text: users(:admin).display_name, count: 0
    assert_includes @response.body, followed_reading.book.title
  end

  test "feed is empty when following nobody" do
    sign_in_as users(:member)
    get feed_url
    assert_response :success
  end
end
