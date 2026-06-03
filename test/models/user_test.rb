require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with email and password" do
    assert User.new(email: "new@example.com", password: "password").valid?
  end

  test "invalid without email" do
    assert_not User.new(password: "password").valid?
  end

  test "invalid with duplicate email" do
    assert_not User.new(email: users(:member).email, password: "password").valid?
  end

  test "role enum" do
    assert users(:member).member?
    assert users(:admin).admin?
  end
end
