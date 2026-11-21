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
    assert_equal "text/html; charset=utf-8", response.headers["content-type"]
    assert_includes response.body, "Too many attempts"
    assert_equal "10", response.headers["X-RateLimit-Limit"]
  end

  test "a format suffix on the path still counts toward the limit" do
    10.times { |i| post "/session.html", params: {session: {email: "guess#{i}@example.com", password: "x"}} }
    post "/session.html", params: {session: {email: "another@example.com", password: "x"}}
    assert_response :too_many_requests

    5.times { |i| post "/passwords.html", params: {password: {email: "user#{i}@example.com"}}, env: {"REMOTE_ADDR" => "10.0.3.1"} }
    post "/passwords.html", params: {password: {email: "user99@example.com"}}, env: {"REMOTE_ADDR" => "10.0.3.1"}
    assert_response :too_many_requests
  end

  # Clearance strips every space before looking the user up, so the throttle must too.
  test "spaces inside an email don't get a fresh per-email bucket" do
    ["m ember@example.com", "me mber@example.com", "mem ber@example.com", "memb er@example.com", "membe r@example.com"].each_with_index do |email, i|
      sign_in_attempt(email, ip: "10.0.4.#{i}")
    end

    sign_in_attempt("member@example.com", ip: "10.0.4.99")

    assert_response :too_many_requests
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

  # /api/v1/session doesn't exist until #219, so the first five 404, but the throttle still counts them.
  test "a throttled API sign-in gets the API's JSON error shape" do
    5.times { post "/api/v1/session", params: {email: "member@example.com"}.to_json, headers: json_headers }

    post "/api/v1/session", params: {email: "member@example.com"}.to_json, headers: json_headers

    assert_response :too_many_requests
    assert_equal({"error" => "Rate limit exceeded"}, JSON.parse(response.body))
  end

  # The API endpoint reads a top-level email, so a decoy session[email] mustn't be what's counted.
  test "the API sign-in throttle counts the top-level email, not a session[email] decoy" do
    5.times do |i|
      body = {email: "member@example.com", session: {email: "decoy#{i}@example.com"}}.to_json
      post "/api/v1/session", params: body, headers: json_headers.merge("REMOTE_ADDR" => "10.0.5.#{i}")
    end

    post "/api/v1/session", params: {email: "member@example.com"}.to_json, headers: json_headers.merge("REMOTE_ADDR" => "10.0.5.99")

    assert_response :too_many_requests
  end

  # Rails lets a query-string param override the body, so the throttle must count that one.
  test "a query-string email is what the sign-in throttle counts" do
    5.times do |i|
      post "/api/v1/session?email=member@example.com&password=guess",
        params: {email: "decoy#{i}@example.com"}.to_json, headers: json_headers.merge("REMOTE_ADDR" => "10.0.6.#{i}")
    end
    post api_v1_session_url, params: {email: "member@example.com", password: "x"}.to_json, headers: json_headers.merge("REMOTE_ADDR" => "10.0.6.99")
    assert_response :too_many_requests

    5.times do |i|
      post "/session?session[email]=moderator@example.com&session[password]=guess",
        params: {session: {email: "decoy#{i}@example.com"}}, env: {"REMOTE_ADDR" => "10.0.7.#{i}"}
    end
    sign_in_attempt("moderator@example.com", ip: "10.0.7.99")
    assert_response :too_many_requests
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

  test "other requests don't count toward the sign-in limits" do
    12.times do
      get new_session_url
      get new_password_url
    end
    assert_response :success

    4.times { |i| post passwords_url, params: {password: {email: "user#{i}@example.com"}} }
    10.times do |i|
      sign_in_attempt("guess#{i}@example.com")
      assert_response :unauthorized
    end
  end

  private

  def sign_in_attempt(email, ip: "127.0.0.1")
    post session_url, params: {session: {email: email, password: "wrong-password"}}, env: {"REMOTE_ADDR" => ip}
  end

  def json_headers
    {"Content-Type" => "application/json", "REMOTE_ADDR" => "10.0.2.1"}
  end
end
