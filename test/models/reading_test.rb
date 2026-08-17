require "test_helper"

class ReadingTest < ActiveSupport::TestCase
  test "valid with user, book, and status" do
    assert Reading.new(user: users(:member), book: books(:two), status: :want_to_read).valid?
  end

  test "invalid without status" do
    assert_not Reading.new(user: users(:member), book: books(:one)).valid?
  end

  test "is_review_public defaults to true" do
    reading = Reading.create!(user: users(:member), book: books(:two), status: :want_to_read)
    assert reading.is_review_public?
  end
end
