require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "email_confirmation includes a confirmation link in both formats" do
    user = users(:member)
    user.update_columns(email_confirmation_token: "test-token")

    email = UserMailer.email_confirmation(user)

    assert_equal [user.email], email.to
    assert_equal "Confirm your email address", email.subject
    assert_match "test-token", email.html_part.body.to_s
    assert_match "test-token", email.text_part.body.to_s
  end
end
