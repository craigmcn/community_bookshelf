require "test_helper"

class RoleAssignmentTest < ActiveSupport::TestCase
  test "valid with a user and role" do
    assert RoleAssignment.new(user: users(:member), role: roles(:admin)).valid?
  end

  test "invalid without a user" do
    assert_not RoleAssignment.new(role: roles(:admin)).valid?
  end

  test "invalid without a role" do
    assert_not RoleAssignment.new(user: users(:member)).valid?
  end

  test "invalid when the same role is assigned to the same user twice" do
    assert_not RoleAssignment.new(user: users(:admin), role: roles(:admin)).valid?
  end
end
