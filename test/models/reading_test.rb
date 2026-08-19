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

  test "valid with dnf status" do
    assert Reading.new(user: users(:member), book: books(:two), status: :dnf).valid?
  end

  test "valid with a format" do
    assert Reading.new(user: users(:member), book: books(:two), status: :reading, format: :audiobook).valid?
  end

  test "valid without a format" do
    assert Reading.new(user: users(:member), book: books(:two), status: :reading, format: nil).valid?
  end

  test "valid with progress_percent between 0 and 100" do
    assert Reading.new(user: users(:member), book: books(:two), status: :reading, progress_percent: 50).valid?
  end

  test "invalid with progress_percent above 100" do
    reading = Reading.new(user: users(:member), book: books(:two), status: :reading, progress_percent: 101)
    assert_not reading.valid?
    assert_includes reading.errors[:progress_percent], "must be less than or equal to 100"
  end

  test "invalid with negative progress_percent" do
    reading = Reading.new(user: users(:member), book: books(:two), status: :reading, progress_percent: -1)
    assert_not reading.valid?
    assert_includes reading.errors[:progress_percent], "must be greater than or equal to 0"
  end

  test "valid when finished_on is on or after started_on" do
    reading = Reading.new(user: users(:member), book: books(:two), status: :finished,
      started_on: Date.new(2026, 1, 1), finished_on: Date.new(2026, 1, 10))
    assert reading.valid?
  end

  test "invalid when finished_on is before started_on" do
    reading = Reading.new(user: users(:member), book: books(:two), status: :finished,
      started_on: Date.new(2026, 1, 10), finished_on: Date.new(2026, 1, 1))
    assert_not reading.valid?
    assert_includes reading.errors[:finished_on], "can't be before the start date"
  end
end
