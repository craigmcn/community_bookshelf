require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "signed-in user can request a resend" do
    sign_in_as users(:member)

    assert_enqueued_emails 1 do
      post email_confirmation_url
    end
    assert_redirected_to edit_account_url
  end

  test "guest cannot request a resend" do
    post email_confirmation_url
    assert_redirected_to sign_in_path
  end

  test "visiting the confirmation link while signed out redirects to sign in with a visible notice" do
    user = User.create!(email: "toconfirm@example.com", password: User::DEFAULT_PASSWORD)
    token = user.email_confirmation_token

    get confirm_email_url(token: token)

    # root_path requires login; redirecting there for a signed-out visitor
    # would just bounce again to sign_in_path, losing this notice to
    # whatever require_login sets there instead.
    assert_redirected_to sign_in_path
    follow_redirect!
    assert_select ".alert-success", text: /Email confirmed/
    assert user.reload.email_confirmed?
  end

  test "visiting the confirmation link while signed in redirects to root with a visible notice" do
    user = User.create!(email: "toconfirmsignedin@example.com", password: User::DEFAULT_PASSWORD)
    token = user.email_confirmation_token
    sign_in_as user

    get confirm_email_url(token: token)

    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert-success", text: /Email confirmed/
    assert user.reload.email_confirmed?
  end

  test "visiting the confirmation link with an invalid token shows an error instead of confirming anything" do
    get confirm_email_url(token: "not-a-real-token")

    assert_redirected_to sign_in_path
    follow_redirect!
    assert_select ".alert-danger", text: /invalid or has expired/
  end

  test "confirming does not require being signed in" do
    user = User.create!(email: "toconfirm2@example.com", password: User::DEFAULT_PASSWORD)
    token = user.email_confirmation_token

    get confirm_email_url(token: token)

    assert_response :redirect
    assert user.reload.email_confirmed?
  end
end
