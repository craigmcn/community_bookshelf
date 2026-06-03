require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get admin_root_url
    assert_redirected_to sign_in_path
  end

  test "member gets forbidden" do
    sign_in_as users(:member)
    get admin_root_url
    assert_response :forbidden
  end

  test "admin can access the dashboard" do
    sign_in_as users(:admin)
    get admin_root_url
    assert_response :success
  end
end
