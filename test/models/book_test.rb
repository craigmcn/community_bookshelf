require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "valid with title, author, and added_by" do
    assert Book.new(title: "Test", author: "Author", added_by: users(:member)).valid?
  end

  test "invalid without title" do
    assert_not Book.new(author: "Author", added_by: users(:member)).valid?
  end

  test "invalid without author" do
    assert_not Book.new(title: "Test", added_by: users(:member)).valid?
  end

  test "valid without isbn, page_count, or published_on" do
    assert Book.new(title: "Test", author: "Author", added_by: users(:member)).valid?
  end

  test "invalid with a zero or negative page_count" do
    book = Book.new(title: "Test", author: "Author", added_by: users(:member), page_count: 0)
    assert_not book.valid?

    book.page_count = -5
    assert_not book.valid?
  end

  test "valid with a positive page_count" do
    book = Book.new(title: "Test", author: "Author", added_by: users(:member), page_count: 320)
    assert book.valid?
  end

  test "clears series_position when series_id is blank" do
    book = Book.new(title: "Test", author: "Author", added_by: users(:member), series_position: 3)
    book.valid?
    assert_nil book.series_position
  end

  test "keeps series_position when a series is set" do
    book = Book.new(
      title: "Test", author: "Author", added_by: users(:member),
      series: series(:one), series_position: 3
    )
    book.valid?
    assert_equal 3, book.series_position
  end
end
