require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get admin_users_url
    assert_redirected_to sign_in_path
  end

  test "member gets forbidden" do
    sign_in_as users(:member)
    get admin_users_url
    assert_response :forbidden
  end

  test "admin can list users" do
    sign_in_as users(:admin)
    get admin_users_url
    assert_response :success
  end

  test "admin can update a user role" do
    sign_in_as users(:admin)
    patch admin_user_url(users(:member)), params: {user: {role_ids: [roles(:moderator).id]}}
    assert_redirected_to admin_users_path
    assert users(:member).reload.moderator?
  end

  test "user list excludes the deleted-user placeholder" do
    placeholder = User.deleted_placeholder

    sign_in_as users(:admin)
    get admin_users_url

    assert_response :success
    assert_not_includes @response.body, placeholder.email
  end
end
