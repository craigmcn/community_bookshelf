require "test_helper"

class RackAttackTest < ActiveSupport::TestCase
  test "resolves the token prefix when it belongs to a real, active token" do
    token = ApiToken.generate!(user: users(:member), name: "test", scopes: ["read:books"])

    req = ActionDispatch::TestRequest.create("HTTP_AUTHORIZATION" => "Bearer #{token.plaintext_token}")

    assert_equal token.token_prefix, Rack::Attack.verified_api_token(req)
  end

  test "returns nil for an expired token" do
    token = ApiToken.generate!(user: users(:member), name: "test", scopes: ["read:books"])
    token.update_column(:expires_at, 1.day.ago)

    req = ActionDispatch::TestRequest.create("HTTP_AUTHORIZATION" => "Bearer #{token.plaintext_token}")

    assert_nil Rack::Attack.verified_api_token(req)
  end

  test "returns nil for a garbage token" do
    req = ActionDispatch::TestRequest.create("HTTP_AUTHORIZATION" => "Bearer not-a-real-token")

    assert_nil Rack::Attack.verified_api_token(req)
  end

  test "returns nil with no Authorization header" do
    req = ActionDispatch::TestRequest.create

    assert_nil Rack::Attack.verified_api_token(req)
  end

  test "a different garbage token on every request still resolves to nil, not a new bucket each time" do
    5.times do
      req = ActionDispatch::TestRequest.create("HTTP_AUTHORIZATION" => "Bearer #{SecureRandom.hex(20)}")
      assert_nil Rack::Attack.verified_api_token(req)
    end
  end

  test "a non-hash scope param yields no email instead of raising" do
    ["session=foo", "session[]=a", "session[email][]=a"].each do |body|
      env = Rack::MockRequest.env_for("/session", :method => "POST", :input => body, "CONTENT_TYPE" => "application/x-www-form-urlencoded")
      assert_nil Rack::Attack.submitted_email(Rack::Attack::Request.new(env), "session"), body
    end
  end

  test "a malformed JSON body yields no email" do
    env = Rack::MockRequest.env_for("/api/v1/session", :method => "POST", :input => "{not json", "CONTENT_TYPE" => "application/json")
    assert_nil Rack::Attack.submitted_email(Rack::Attack::Request.new(env), nil)
  end

  test "route_path drops a format suffix and trailing slash" do
    ["/session", "/session.json", "/session.html", "/session/"].each do |path|
      assert_equal "/session", Rack::Attack.route_path(Rack::Attack::Request.new(Rack::MockRequest.env_for(path))), path
    end
  end

  test "a valid remember_token cookie buckets per user" do
    users(:member).reset_remember_token!
    req = api_request("HTTP_COOKIE" => "remember_token=#{users(:member).remember_token}")

    assert_equal "user:#{users(:member).id}", Rack::Attack.verified_api_client(req)
  end

  test "an unknown remember_token cookie is unauthenticated" do
    assert_nil Rack::Attack.verified_api_client(api_request("HTTP_COOKIE" => "remember_token=nope"))
  end

  # Matches the API's precedence: a header means token auth only, so the cookie isn't consulted.
  test "a garbage token beside a valid cookie is unauthenticated" do
    users(:member).reset_remember_token!
    req = api_request("HTTP_COOKIE" => "remember_token=#{users(:member).remember_token}", "HTTP_AUTHORIZATION" => "Bearer garbage")

    assert_nil Rack::Attack.verified_api_client(req)
  end

  private

  def api_request(env)
    Rack::Attack::Request.new(Rack::MockRequest.env_for("/api/v1/books", env))
  end
end
