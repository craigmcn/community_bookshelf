require "test_helper"

class ShelfBookTest < ActiveSupport::TestCase
  test "valid with a shelf and book" do
    assert ShelfBook.new(shelf: shelves(:one), book: books(:two)).valid?
  end

  test "invalid adding the same book to the same shelf twice" do
    assert_not ShelfBook.new(shelf: shelves(:one), book: books(:one)).valid?
  end

  test "valid adding the same book to a different shelf" do
    assert ShelfBook.new(shelf: shelves(:two), book: books(:one)).valid?
  end
end
