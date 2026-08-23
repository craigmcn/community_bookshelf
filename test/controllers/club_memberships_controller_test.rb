require "test_helper"

class ClubMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
  end

  test "member can join a club" do
    sign_in_as users(:moderator)
    post club_membership_url(@club)

    assert_redirected_to club_url(@club)
    assert @club.member?(users(:moderator))
  end

  test "member can leave a club" do
    @club.club_memberships.create!(user: users(:moderator))
    sign_in_as users(:moderator)

    delete club_membership_url(@club)

    assert_redirected_to club_url(@club)
    assert_not @club.reload.member?(users(:moderator))
  end

  test "leaving a club twice is idempotent" do
    sign_in_as users(:moderator)

    delete club_membership_url(@club)

    assert_redirected_to club_url(@club)
    assert_not @club.reload.member?(users(:moderator))
  end

  test "joining a club you already belong to is blocked before any duplicate row is created" do
    @club.club_memberships.create!(user: users(:moderator))
    sign_in_as users(:moderator)

    assert_no_difference "ClubMembership.count" do
      post club_membership_url(@club)
    end
  end
end
