require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "member is redirected to root after sign in" do
    post session_url, params: {session: {email: users(:member).email, password: User::DEFAULT_PASSWORD}}
    assert_redirected_to root_path
  end

  test "admin is redirected to admin root after sign in" do
    post session_url, params: {session: {email: users(:admin).email, password: User::DEFAULT_PASSWORD}}
    assert_redirected_to admin_root_path
  end

  test "invalid credentials return unauthorized" do
    post session_url, params: {session: {email: users(:member).email, password: "wrong"}}
    assert_response :unauthorized
  end
end
