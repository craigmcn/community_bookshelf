require "test_helper"

# /api/v1 accepts the Clearance cookie as well as bearer tokens (#219).
class Api::CookieAuthTest < ActionDispatch::IntegrationTest
  setup { users(:member).reset_remember_token! }

  test "a cookie session can read, with every scope" do
    sign_in_via_api

    get api_v1_books_url
    assert_response :success

    get api_v1_stats_url
    assert_response :success
    assert_equal "120", response.headers["X-RateLimit-Limit"]
  end

  test "a cookie write without the CSRF token is a 403" do
    sign_in_via_api

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers

    assert_response :forbidden
    assert_equal({"error" => "Invalid CSRF token"}, JSON.parse(response.body))
  end

  test "a cookie write with the CSRF token succeeds" do
    csrf_token = sign_in_via_api

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge("X-CSRF-Token" => csrf_token)

    assert_response :created
  end

  test "a cookie PATCH needs the CSRF token too" do
    csrf_token = sign_in_via_api

    patch mark_all_read_api_v1_notifications_url, headers: json_headers
    assert_response :forbidden

    patch mark_all_read_api_v1_notifications_url, headers: json_headers.merge("X-CSRF-Token" => csrf_token)
    assert_response :success
  end

  test "signing in again makes the earlier CSRF token stale" do
    old_token = sign_in_via_api
    sign_in_via_api

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge("X-CSRF-Token" => old_token)

    assert_response :forbidden
  end

  test "the CSRF token from GET /session also works" do
    sign_in_as users(:member)
    get api_v1_session_url
    csrf_token = JSON.parse(response.body)["csrf_token"]

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge("X-CSRF-Token" => csrf_token)

    assert_response :created
  end

  test "an invalid token is a 401 even with a valid cookie" do
    sign_in_via_api

    get api_v1_books_url, headers: {"Authorization" => "Bearer garbage"}

    assert_response :unauthorized
    assert_equal({"error" => "Invalid or missing API token"}, JSON.parse(response.body))
  end

  test "a token request needs no CSRF token, even with a cookie present" do
    sign_in_via_api

    post api_v1_readings_url, params: reading_params.to_json, headers: json_headers.merge(auth_headers(users(:member)))

    assert_response :created
  end

  test "a token's scopes still apply when a cookie is present" do
    sign_in_via_api

    get api_v1_stats_url, headers: auth_headers(users(:member), scopes: ["read:books"])

    assert_response :forbidden
  end

  test "no token and no cookie is a 401" do
    get api_v1_books_url

    assert_response :unauthorized
  end

  private

  def json_headers
    {"Content-Type" => "application/json"}
  end

  def reading_params
    {reading: {book_id: books(:two).id, status: "reading"}}
  end

  def sign_in_via_api
    post api_v1_session_url, params: {email: "member@example.com", password: "correct-horse-shelf"}.to_json, headers: json_headers
    assert_response :created
    JSON.parse(response.body)["csrf_token"]
  end
end
