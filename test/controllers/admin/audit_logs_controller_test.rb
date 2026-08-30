require "test_helper"

class Admin::AuditLogsControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get admin_audit_logs_url
    assert_redirected_to sign_in_path
  end

  test "member gets forbidden" do
    sign_in_as users(:member)
    get admin_audit_logs_url
    assert_response :forbidden
  end

  test "moderator gets forbidden" do
    sign_in_as users(:moderator)
    get admin_audit_logs_url
    assert_response :forbidden
  end

  test "admin can list audit log entries" do
    AuditLog.create!(actor: users(:admin), action: "destroy_book", subject: books(:one), details: {title: "Some Book"})

    sign_in_as users(:admin)
    get admin_audit_logs_url

    assert_response :success
    assert_match "Some Book", @response.body
  end
end
