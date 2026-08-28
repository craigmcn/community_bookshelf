require "test_helper"

class Api::RateLimitHeadersTest < ActionDispatch::IntegrationTest
  test "a successful authenticated request carries X-RateLimit headers" do
    get api_v1_books_url, headers: auth_headers(users(:member))

    assert_response :success
    assert_equal "120", response.headers["X-RateLimit-Limit"]
    assert response.headers["X-RateLimit-Remaining"].to_i <= 120
    assert response.headers["X-RateLimit-Reset"].present?
  end

  test "an unauthenticated request carries the IP-bucket X-RateLimit headers" do
    get api_v1_books_url, headers: {"Authorization" => "Bearer garbage"}

    assert_response :unauthorized
    assert_equal "30", response.headers["X-RateLimit-Limit"]
  end
end
