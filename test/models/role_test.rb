require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "valid with a name" do
    assert Role.new(name: "editor").valid?
  end

  test "invalid without a name" do
    assert_not Role.new.valid?
  end

  test "invalid with a duplicate name" do
    assert_not Role.new(name: roles(:admin).name).valid?
  end

  test "has many users through role assignments" do
    assert_includes roles(:admin).users, users(:admin)
  end
end
