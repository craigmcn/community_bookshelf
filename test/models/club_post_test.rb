require "test_helper"

class ClubPostTest < ActiveSupport::TestCase
  setup do
    @club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
  end

  test "a non-spoiler post is visible to anyone" do
    post = ClubPost.create!(club: @club, user: users(:member), body: "Excited to start!", spoiler: false)
    assert post.visible_to?(users(:moderator))
  end

  test "a spoiler post is hidden from someone who hasn't finished the book" do
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    post = ClubPost.create!(club: @club, user: users(:member), body: "The twist is...", spoiler: true)
    assert_not post.visible_to?(other_member)
  end

  test "a spoiler post is visible to its author" do
    post = ClubPost.create!(club: @club, user: users(:member), body: "The twist is...", spoiler: true)
    assert post.visible_to?(users(:member))
  end

  test "a spoiler post is visible to a moderator" do
    post = ClubPost.create!(club: @club, user: users(:member), body: "The twist is...", spoiler: true)
    assert post.visible_to?(users(:admin))
  end

  test "a spoiler post is visible to someone who finished the book" do
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    Reading.create!(user: other_member, book: @club.book, status: :finished)
    post = ClubPost.create!(club: @club, user: users(:member), body: "The twist is...", spoiler: true)
    assert post.visible_to?(other_member)
  end

  test "a spoiler post is hidden from a guest" do
    post = ClubPost.create!(club: @club, user: users(:member), body: "The twist is...", spoiler: true)
    assert_not post.visible_to?(nil)
  end
end
