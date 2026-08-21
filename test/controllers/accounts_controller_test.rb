require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get edit_account_url
    assert_redirected_to sign_in_path
  end

  test "member can view their account edit page" do
    sign_in_as users(:member)
    get edit_account_url
    assert_response :success
  end

  test "member can update their name and bio" do
    sign_in_as users(:member)
    patch account_url, params: {user: {name: "Sam Reader", bio: "I like fantasy novels."}}

    assert_redirected_to edit_account_url
    users(:member).reload
    assert_equal "Sam Reader", users(:member).name
    assert_equal "I like fantasy novels.", users(:member).bio
  end

  test "member can upload an avatar" do
    sign_in_as users(:member)
    avatar = fixture_file_upload("avatar.png", "image/png")

    patch account_url, params: {user: {avatar: avatar}}

    assert_redirected_to edit_account_url
    assert users(:member).reload.avatar.attached?
  end

  test "member can remove their avatar" do
    user = users(:member)
    user.avatar.attach(fixture_file_upload("avatar.png", "image/png"))

    sign_in_as user
    patch account_url, params: {remove_avatar: "1", user: {name: user.name}}

    assert_redirected_to edit_account_url
    assert_not user.reload.avatar.attached?
  end

  test "member can delete their account with the correct password" do
    sign_in_as users(:member)
    User.deleted_placeholder # pre-create so the assertion below isn't masked by its own +1

    assert_difference "User.count", -1 do
      delete account_url, params: {current_password: User::DEFAULT_PASSWORD}
    end
    assert_redirected_to root_path
  end

  test "member cannot delete their account with the wrong password" do
    sign_in_as users(:member)

    assert_no_difference "User.count" do
      delete account_url, params: {current_password: "wrong-password"}
    end
    assert_response :unprocessable_content
  end
end
