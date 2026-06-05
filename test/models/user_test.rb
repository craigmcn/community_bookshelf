require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with email and password" do
    assert User.new(email: "new@example.com", password: User::DEFAULT_PASSWORD).valid?
  end

  test "invalid without email" do
    assert_not User.new(password: User::DEFAULT_PASSWORD).valid?
  end

  test "invalid with duplicate email" do
    assert_not User.new(email: users(:member).email, password: User::DEFAULT_PASSWORD).valid?
  end

  test "role enum" do
    assert users(:member).member?
    assert users(:admin).admin?
  end

  test "new user is assigned member role on create" do
    user = User.create!(email: "newuser@example.com", password: User::DEFAULT_PASSWORD)
    assert user.member?
    assert user.roles.exists?(name: "member")
  end
end
