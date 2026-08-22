require "test_helper"

class ClubsControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get clubs_url
    assert_redirected_to sign_in_path
  end

  test "member can view the club list" do
    sign_in_as users(:member)
    get clubs_url
    assert_response :success
  end

  test "member can create a club and is auto-joined" do
    sign_in_as users(:member)
    post clubs_url, params: {club: {name: "Sci-Fi Society", book_id: books(:one).id, description: "For fans of speculative fiction."}}

    club = Club.last
    assert_redirected_to club_url(club)
    assert_equal users(:member), club.created_by
    assert club.member?(users(:member))
  end

  test "any signed-in member can view a club" do
    club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:moderator))
    sign_in_as users(:member)

    get club_url(club)
    assert_response :success
  end

  test "only the creator or a moderator can edit a club" do
    club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    sign_in_as other_member

    get edit_club_url(club)
    assert_redirected_to root_path
  end

  test "a moderator can edit someone else's club" do
    club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
    sign_in_as users(:moderator)

    get edit_club_url(club)
    assert_response :success
  end
end
