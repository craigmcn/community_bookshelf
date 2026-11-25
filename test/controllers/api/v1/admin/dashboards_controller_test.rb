require "test_helper"

class Api::V1::Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors get a 401" do
    get api_v1_admin_dashboard_url
    assert_response :unauthorized
  end

  test "members and moderators get a 403" do
    [:member, :moderator].each do |user|
      sign_in_as users(user)
      get api_v1_admin_dashboard_url
      assert_response :forbidden
      assert_equal({"error" => "You are not authorized to perform this action."}, JSON.parse(response.body))
    end
  end

  # Admin endpoints are cookie-only: a leaked token must not be able to change roles.
  test "an admin's API token is refused" do
    get api_v1_admin_dashboard_url, headers: auth_headers(users(:admin))
    assert_response :forbidden
    assert_equal({"error" => "This endpoint takes a session cookie, not an API token"}, JSON.parse(response.body))
  end

  test "an admin sees totals, without the deleted-user placeholder, and the most-read books" do
    user_count = User.count
    User.deleted_placeholder
    2.times { Reading.create!(user: users(:member), book: books(:two), status: :want_to_read) }

    sign_in_as users(:admin)
    get api_v1_admin_dashboard_url

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [user_count, Book.count, Reading.count], body.values_at("total_users", "total_books", "total_readings")
    assert_equal({"id" => books(:two).id, "title" => "1984", "author" => "George Orwell", "readings_count" => 2}, body["popular_books"].first)
    assert_equal [2, 1], body["popular_books"].pluck("readings_count")
  end
end
