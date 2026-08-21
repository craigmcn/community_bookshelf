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

  test "visiting the confirmation link with a valid token confirms the account" do
    user = User.create!(email: "toconfirm@example.com", password: User::DEFAULT_PASSWORD)
    token = user.email_confirmation_token

    get confirm_email_url(token: token)

    assert_redirected_to root_path
    assert user.reload.email_confirmed?
  end

  test "visiting the confirmation link with an invalid token does not confirm anything" do
    get confirm_email_url(token: "not-a-real-token")

    assert_redirected_to root_path
  end

  test "confirming does not require being signed in" do
    user = User.create!(email: "toconfirm2@example.com", password: User::DEFAULT_PASSWORD)
    token = user.email_confirmation_token

    get confirm_email_url(token: token)

    assert_response :redirect
    assert user.reload.email_confirmed?
  end
end
