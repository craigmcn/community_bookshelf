require "test_helper"

class SeriesTest < ActiveSupport::TestCase
  test "valid with a name" do
    assert Series.new(name: "New Series").valid?
  end

  test "invalid without a name" do
    assert_not Series.new.valid?
  end

  test "invalid with a duplicate name" do
    assert_not Series.new(name: series(:one).name).valid?
  end

  test "destroying a series nullifies its books' series association instead of destroying them" do
    book = books(:one)
    book.update!(series: series(:one))

    assert_no_difference "Book.count" do
      series(:one).destroy
    end
    assert_nil book.reload.series_id
  end
end
