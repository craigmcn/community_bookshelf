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
end
