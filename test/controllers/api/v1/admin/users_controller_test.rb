require "test_helper"

class Api::V1::Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors get a 401" do
    get api_v1_admin_users_url
    assert_response :unauthorized
  end

  test "members and moderators can't list users" do
    [:member, :moderator].each do |user|
      sign_in_as users(user)
      get api_v1_admin_users_url
      assert_response :forbidden
    end
  end

  test "an admin's API token is refused" do
    get api_v1_admin_users_url, headers: auth_headers(users(:admin))
    assert_response :forbidden

    patch api_v1_admin_user_url(users(:member)), params: {user: {roles: ["admin"]}}, headers: auth_headers(users(:admin))
    assert_response :forbidden
    assert_not users(:member).reload.admin?
  end

  test "an admin lists users by email with their roles, without the deleted-user placeholder" do
    placeholder = User.deleted_placeholder

    sign_in_as users(:admin)
    get api_v1_admin_users_url

    assert_response :success
    listed = JSON.parse(response.body)["users"]
    assert_equal listed.pluck("email").sort, listed.pluck("email")
    assert_not_includes listed.pluck("email"), placeholder.email
    member = listed.find { |user| user["id"] == users(:member).id }
    assert_equal ["member"], member["roles"]
    assert_equal %w[created_at email id roles], member.keys.sort
  end

  test "an admin replaces a user's roles, and it's audited" do
    assert_difference "AuditLog.count", 1 do
      update_roles users(:member), ["member", "moderator"]
    end

    assert_response :success
    assert_equal ["member", "moderator"], JSON.parse(response.body)["roles"]
    assert_equal ["member", "moderator"], users(:member).reload.roles.pluck(:name).sort
    log = AuditLog.last
    assert_equal ["update_roles", users(:admin), users(:member)], [log.action, log.actor, log.subject]
    assert_equal({"from" => ["member"], "to" => ["member", "moderator"]}, log.details)
  end

  test "an empty list removes every role, as on the website" do
    update_roles users(:member), []

    assert_response :success
    assert_empty users(:member).reload.roles
  end

  test "an unknown role is a 422 and changes nothing" do
    assert_no_difference "AuditLog.count" do
      update_roles users(:member), ["member", "owner"]
    end

    assert_response :unprocessable_content
    assert_equal({"errors" => ["Unknown roles: owner"]}, JSON.parse(response.body))
    assert_equal ["member"], users(:member).reload.roles.pluck(:name)
  end

  # Omitting the list isn't the same as an empty one: a malformed body must not strip roles.
  test "a missing or malformed roles list changes nothing" do
    csrf_token = admin_csrf_token

    # Rails drops nulls from arrays, so [null] would otherwise read as [] and strip every role.
    bodies = [{user: {name: "x"}}, {user: {roles: "admin"}}, {user: {roles: nil}}, {user: {roles: [nil]}},
      {user: {roles: ["member", nil]}}, {user: {roles: [["admin"]]}}, {user: {roles: [{name: "admin"}]}},
      {user: {roles: [1]}}, {user: "admin"}, [], {}]
    bodies.each do |body|
      patch api_v1_admin_user_url(users(:member)), params: body.to_json, headers: json_headers(csrf_token)
      assert_response :bad_request, body.inspect
      assert_equal({"error" => "user.roles must be a list of role names"}, JSON.parse(response.body), body.inspect)
      assert_equal ["member"], users(:member).reload.roles.pluck(:name)
    end
  end

  test "a non-JSON body is a 415 and changes nothing" do
    csrf_token = admin_csrf_token

    patch api_v1_admin_user_url(users(:member)), params: {user: {roles: ["admin"]}}, headers: {"X-CSRF-Token" => csrf_token}

    assert_response :unsupported_media_type
    assert_not users(:member).reload.admin?
  end

  test "a moderator can't change roles" do
    sign_in_as users(:moderator)
    get api_v1_session_url
    csrf_token = JSON.parse(response.body)["csrf_token"]

    patch api_v1_admin_user_url(users(:moderator)), params: {user: {roles: ["admin"]}}.to_json, headers: json_headers(csrf_token)

    assert_response :forbidden
    assert_not users(:moderator).reload.admin?
  end

  test "changing roles needs the CSRF token" do
    sign_in_as users(:admin)

    patch api_v1_admin_user_url(users(:member)), params: {user: {roles: ["admin"]}}.to_json, headers: json_headers

    assert_response :forbidden
    assert_equal({"error" => "Invalid CSRF token"}, JSON.parse(response.body))
    assert_not users(:member).reload.admin?
  end

  test "the deleted-user placeholder can't be updated" do
    placeholder = User.deleted_placeholder
    update_roles placeholder, ["admin"]

    assert_response :not_found
    assert_not placeholder.reload.admin?
  end

  private

  def update_roles(user, roles)
    csrf_token = admin_csrf_token
    patch api_v1_admin_user_url(user), params: {user: {roles: roles}}.to_json, headers: json_headers(csrf_token)
  end

  def admin_csrf_token
    sign_in_as users(:admin)
    get api_v1_session_url
    JSON.parse(response.body)["csrf_token"]
  end

  def json_headers(csrf_token = nil)
    {"Content-Type" => "application/json", "X-CSRF-Token" => csrf_token}.compact
  end
end
