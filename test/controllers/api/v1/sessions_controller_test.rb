require "test_helper"

# Cookie sign-in for the SPA (#219).
class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  # Fixtures skip callbacks, so fixture users have no remember_token and Clearance sets no cookie.
  setup { users(:member).reset_remember_token! }

  test "signing in returns the user and a CSRF token, and sets the cookie" do
    sign_in_via_api

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal users(:member).id, body.dig("user", "id")
    assert_equal "member@example.com", body.dig("user", "email")
    assert_includes body.dig("user", "roles"), "member"
    assert body["csrf_token"].present?
    assert cookies[Clearance.configuration.cookie_name].present?
  end

  test "a wrong password is a 401" do
    sign_in_via_api(password: "wrong")

    assert_response :unauthorized
    assert JSON.parse(response.body)["error"].present?
    assert_nil cookies[Clearance.configuration.cookie_name].presence
  end

  test "a form-encoded sign-in is refused, so a cross-site form can't log a browser in" do
    post api_v1_session_url, params: {email: "member@example.com", password: "correct-horse-shelf"}

    assert_response :unsupported_media_type
  end

  test "the session endpoints refuse API tokens" do
    get api_v1_session_url, headers: auth_headers(users(:member))
    assert_response :forbidden

    post api_v1_session_url, params: credentials.to_json, headers: json_headers.merge(auth_headers(users(:member)))
    assert_response :forbidden
  end

  test "show returns the signed-in user, or 401 when signed out" do
    get api_v1_session_url
    assert_response :unauthorized

    sign_in_via_api
    get api_v1_session_url

    assert_response :success
    assert_equal users(:member).id, JSON.parse(response.body).dig("user", "id")
  end

  test "signing out needs the CSRF token" do
    csrf_token = sign_in_via_api

    delete api_v1_session_url
    assert_response :forbidden
    assert_equal({"error" => "Invalid CSRF token"}, JSON.parse(response.body))

    delete api_v1_session_url, headers: {"X-CSRF-Token" => csrf_token}
    assert_response :no_content

    get api_v1_session_url
    assert_response :unauthorized
  end

  private

  def credentials(password: "correct-horse-shelf")
    {email: "member@example.com", password: password}
  end

  def json_headers
    {"Content-Type" => "application/json"}
  end

  def sign_in_via_api(password: "correct-horse-shelf")
    post api_v1_session_url, params: credentials(password: password).to_json, headers: json_headers
    JSON.parse(response.body)["csrf_token"]
  end
end
