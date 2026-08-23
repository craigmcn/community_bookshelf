require "test_helper"

class ClubTest < ActiveSupport::TestCase
  test "valid with a name and book" do
    club = Club.new(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
    assert club.valid?
  end

  test "invalid without a name" do
    club = Club.new(book: books(:one), created_by: users(:member))
    assert_not club.valid?
  end

  test "creator is automatically a member" do
    club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
    assert club.member?(users(:member))
  end
end
