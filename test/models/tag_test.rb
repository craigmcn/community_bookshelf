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

  test "defaults to the genre category" do
    tag = Tag.create!(name: "new-tag")
    assert tag.genre?
  end

  test "can be created as a mood or pace tag" do
    assert Tag.create!(name: "dark", category: "mood").mood?
    assert Tag.create!(name: "fast-paced", category: "pace").pace?
  end
end
