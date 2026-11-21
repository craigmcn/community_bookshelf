require "test_helper"

# Clearance's remember_token is the long-lived sign-in credential, so it gets the same
# Secure/SameSite treatment as the Rails session cookie (#249).
class RememberTokenCookieTest < ActionDispatch::IntegrationTest
  # Fixtures skip callbacks, so fixture users have no remember_token and Clearance sets no cookie.
  setup { users(:member).reset_remember_token! }

  test "signing in sets remember_token as HttpOnly and SameSite=Lax" do
    post session_url, params: {session: {email: users(:member).email, password: "correct-horse-shelf"}}

    cookie = remember_token_set_cookie
    assert cookie, "expected a remember_token Set-Cookie header"
    assert_match(/;\s*httponly/i, cookie)
    assert_match(/;\s*samesite=lax/i, cookie)
  end

  # Test env doesn't force SSL, so check the tie to force_ssl rather than a production header.
  test "remember_token is Secure exactly where SSL is enforced" do
    assert_equal Rails.application.config.force_ssl, Clearance.configuration.secure_cookie
  end

  test "remember_token carries Secure when the setting is on" do
    original = Clearance.configuration.secure_cookie
    Clearance.configuration.secure_cookie = true
    https!

    post session_url, params: {session: {email: users(:member).email, password: "correct-horse-shelf"}}

    assert_match(/;\s*secure/i, remember_token_set_cookie)
  ensure
    Clearance.configuration.secure_cookie = original
  end

  private

  def remember_token_set_cookie
    Array(response.headers["set-cookie"]).flat_map { |h| h.split("\n") }.find { |c| c.start_with?("remember_token=") }
  end
end
