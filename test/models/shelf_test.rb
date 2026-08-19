require "test_helper"

class ShelfTest < ActiveSupport::TestCase
  test "valid with a user and name" do
    assert Shelf.new(user: users(:member), name: "2026 TBR").valid?
  end

  test "invalid without a name" do
    assert_not Shelf.new(user: users(:member)).valid?
  end

  test "invalid with a duplicate name for the same user" do
    assert_not Shelf.new(user: users(:member), name: shelves(:one).name).valid?
  end

  test "valid with a duplicate name for a different user" do
    assert Shelf.new(user: users(:admin), name: shelves(:one).name).valid?
  end

  test "books returns books added to the shelf" do
    assert_equal [books(:one)], shelves(:one).books
  end
end
