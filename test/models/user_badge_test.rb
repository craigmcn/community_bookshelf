require "test_helper"

class UserBadgeTest < ActiveSupport::TestCase
  test "valid with a known badge key" do
    badge = UserBadge.new(user: users(:member), badge_key: "books_finished_1", awarded_at: Time.current)
    assert badge.valid?
  end

  test "invalid with an unknown badge key" do
    badge = UserBadge.new(user: users(:member), badge_key: "not_a_real_badge", awarded_at: Time.current)
    assert_not badge.valid?
  end

  test "invalid with a duplicate badge for the same user" do
    UserBadge.create!(user: users(:member), badge_key: "books_finished_1", awarded_at: Time.current)
    duplicate = UserBadge.new(user: users(:member), badge_key: "books_finished_1", awarded_at: Time.current)
    assert_not duplicate.valid?
  end

  test "badge returns the matching Badge definition" do
    user_badge = UserBadge.create!(user: users(:member), badge_key: "books_finished_1", awarded_at: Time.current)
    assert_equal "books_finished_1", user_badge.badge.key
  end
end
