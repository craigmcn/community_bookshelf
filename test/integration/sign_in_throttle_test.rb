require "test_helper"

# Rails.cache is a :null_store in test, so counts never persist there. Each test swaps in a
# MemoryStore so the throttles can actually fire (#248).
class SignInThrottleTest < ActionDispatch::IntegrationTest
  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rack::Attack.cache.store = @original_store
  end

  test "an IP is limited to 10 sign-in attempts a minute, across emails" do
    10.times do |i|
      sign_in_attempt("guess#{i}@example.com")
      assert_response :unauthorized
    end

    sign_in_attempt("another@example.com")

    assert_response :too_many_requests
    assert_includes response.body, "Too many attempts"
    assert_equal "10", response.headers["X-RateLimit-Limit"]
  end

  test "an email is limited to 5 sign-in attempts a minute, across IPs" do
    5.times do |i|
      sign_in_attempt("Member@Example.com ", ip: "10.0.0.#{i}")
      assert_response :unauthorized
    end

    sign_in_attempt("member@example.com", ip: "10.0.0.99")
    assert_response :too_many_requests

    sign_in_attempt("someone-else@example.com", ip: "10.0.0.99")
    assert_response :unauthorized
  end

  test "a throttled API sign-in gets the API's JSON error shape" do
    5.times { post "/api/v1/session", params: {email: "member@example.com"}.to_json, headers: json_headers }

    post "/api/v1/session", params: {email: "member@example.com"}.to_json, headers: json_headers

    assert_response :too_many_requests
    assert_equal({"error" => "Rate limit exceeded"}, JSON.parse(response.body))
  end

  test "an IP is limited to 5 password reset requests a minute" do
    5.times { |i| post passwords_url, params: {password: {email: "user#{i}@example.com"}} }

    post passwords_url, params: {password: {email: "user99@example.com"}}

    assert_response :too_many_requests
  end

  test "an email gets at most 3 password reset requests per 15 minutes, across IPs" do
    3.times do |i|
      post passwords_url, params: {password: {email: "member@example.com"}}, env: {"REMOTE_ADDR" => "10.0.1.#{i}"}
      assert_not_equal 429, response.status
    end

    post passwords_url, params: {password: {email: "member@example.com"}}, env: {"REMOTE_ADDR" => "10.0.1.99"}

    assert_response :too_many_requests
  end

  test "other pages are not throttled" do
    12.times { get new_session_url }

    assert_response :success
  end

  private

  def sign_in_attempt(email, ip: "127.0.0.1")
    post session_url, params: {session: {email: email, password: "wrong-password"}}, env: {"REMOTE_ADDR" => ip}
  end

  def json_headers
    {"Content-Type" => "application/json", "REMOTE_ADDR" => "10.0.2.1"}
  end
end
