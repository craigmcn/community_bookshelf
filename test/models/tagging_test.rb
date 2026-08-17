require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  test "valid with a book and tag" do
    assert Tagging.new(book: books(:one), tag: tags(:two)).valid?
  end

  test "invalid tagging the same book with the same tag twice" do
    assert_not Tagging.new(book: books(:one), tag: tags(:one)).valid?
  end
end
