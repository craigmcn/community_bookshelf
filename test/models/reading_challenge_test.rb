require "test_helper"

class ReadingChallengeTest < ActiveSupport::TestCase
  test "valid with a user, year, and goal" do
    assert ReadingChallenge.new(user: users(:member), year: 2026, goal: 20).valid?
  end

  test "invalid without a goal" do
    assert_not ReadingChallenge.new(user: users(:member), year: 2026).valid?
  end

  test "invalid with a goal of zero" do
    assert_not ReadingChallenge.new(user: users(:member), year: 2026, goal: 0).valid?
  end

  test "invalid with a duplicate year for the same user" do
    ReadingChallenge.create!(user: users(:member), year: 2026, goal: 20)
    duplicate = ReadingChallenge.new(user: users(:member), year: 2026, goal: 5)
    assert_not duplicate.valid?
  end

  test "valid with a duplicate year for a different user" do
    ReadingChallenge.create!(user: users(:member), year: 2026, goal: 20)
    assert ReadingChallenge.new(user: users(:admin), year: 2026, goal: 5).valid?
  end

  test "books_finished_count counts finished readings in that year" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: Date.new(2026, 3, 1))
    Reading.create!(user: member, book: books(:two), status: :finished, finished_on: Date.new(2025, 3, 1))
    challenge = ReadingChallenge.create!(user: member, year: 2026, goal: 5)

    assert_equal 1, challenge.books_finished_count
  end

  test "completed? is true once the goal is reached" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: Date.new(2026, 3, 1))
    challenge = ReadingChallenge.create!(user: member, year: 2026, goal: 1)

    assert challenge.completed?
  end

  test "progress_percent is capped at 100" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: Date.new(2026, 3, 1))
    challenge = ReadingChallenge.create!(user: member, year: 2026, goal: 1)

    assert_equal 100, challenge.progress_percent
  end

  test "books_finished_count is memoized per instance" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: Date.new(2026, 3, 1))
    challenge = ReadingChallenge.create!(user: member, year: 2026, goal: 5)

    assert_equal 1, challenge.books_finished_count
    Reading.create!(user: member, book: books(:two), status: :finished, finished_on: Date.new(2026, 4, 1))
    assert_equal 1, challenge.books_finished_count, "expected the memoized count, not a fresh query"
  end
end
