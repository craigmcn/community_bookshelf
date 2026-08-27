require "test_helper"

class RackAttackTest < ActiveSupport::TestCase
  test "resolves the token when it belongs to a real user" do
    user = users(:member)
    user.regenerate_api_token if user.api_token.blank?

    req = ActionDispatch::TestRequest.create("HTTP_AUTHORIZATION" => "Bearer #{user.api_token}")

    assert_equal user.api_token, Rack::Attack.verified_api_token(req)
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
