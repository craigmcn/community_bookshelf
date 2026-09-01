require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "generate! returns a token with the plaintext secret set" do
    token = ApiToken.generate!(user: users(:member), name: "test", scopes: ["read:books"])

    assert token.plaintext_token.present?
    assert token.persisted?
    assert_not_equal token.plaintext_token, token.token_digest
  end

  test "authenticate returns the token for a valid, unexpired secret" do
    token = ApiToken.generate!(user: users(:member), name: "test", scopes: ["read:books"])

    assert_equal token, ApiToken.authenticate(token.plaintext_token)
  end

  test "authenticate returns nil for a wrong secret sharing a real prefix" do
    token = ApiToken.generate!(user: users(:member), name: "test", scopes: ["read:books"])
    tampered = token.plaintext_token.sub(/.{4}\z/, "0000")

    assert_nil ApiToken.authenticate(tampered)
  end

  test "authenticate returns nil for a garbage token" do
    assert_nil ApiToken.authenticate("cb_not-a-real-token")
  end

  test "authenticate returns nil for an expired token" do
    token = ApiToken.generate!(user: users(:member), name: "test", scopes: ["read:books"], expires_at: 1.day.ago)

    assert_nil ApiToken.authenticate(token.plaintext_token)
  end

  test "invalid without at least one scope" do
    token = ApiToken.new(user: users(:member), name: "test", scopes: [])

    assert_not token.valid?
    assert_includes token.errors[:scopes], "can't be blank"
  end

  test "invalid with an unknown scope" do
    token = ApiToken.new(user: users(:member), name: "test", scopes: ["delete:everything"])

    assert_not token.valid?
    assert_match(/unknown scope/, token.errors[:scopes].first)
  end

  test "expired? is true only once expires_at has passed" do
    future = ApiToken.new(expires_at: 1.day.from_now)
    past = ApiToken.new(expires_at: 1.day.ago)
    never = ApiToken.new(expires_at: nil)

    assert_not future.expired?
    assert past.expired?
    assert_not never.expired?
  end
end
