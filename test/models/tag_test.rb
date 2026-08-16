require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid with a name" do
    assert Tag.new(name: "new-tag").valid?
  end

  test "invalid without a name" do
    assert_not Tag.new.valid?
  end

  test "normalizes name to stripped, downcased form before validation" do
    tag = Tag.new(name: "  Coming-of-Age  ")
    tag.valid?
    assert_equal "coming-of-age", tag.name
  end

  test "invalid with a duplicate name after normalization" do
    assert_not Tag.new(name: tags(:one).name.upcase).valid?
  end
end
