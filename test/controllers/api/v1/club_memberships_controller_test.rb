require "test_helper"

class Api::V1::ClubMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
    @moderator = users(:moderator)
  end

  test "no token is rejected" do
    post api_v1_club_membership_url(@club)
    assert_response :unauthorized
  end

  test "member can join a club" do
    post api_v1_club_membership_url(@club), headers: auth_headers(@moderator)
    assert_response :created
    assert @club.member?(@moderator)
  end

  test "member can leave a club" do
    @club.club_memberships.create!(user: @moderator)

    delete api_v1_club_membership_url(@club), headers: auth_headers(@moderator)
    assert_response :no_content
    assert_not @club.reload.member?(@moderator)
  end

  test "leaving a club twice is idempotent" do
    delete api_v1_club_membership_url(@club), headers: auth_headers(@moderator)
    assert_response :no_content

    assert_no_difference "ClubMembership.count" do
      delete api_v1_club_membership_url(@club), headers: auth_headers(@moderator)
    end
    assert_response :no_content
  end

  test "joining a club you already belong to is blocked before any duplicate row is created" do
    @club.club_memberships.create!(user: @moderator)

    assert_no_difference "ClubMembership.count" do
      post api_v1_club_membership_url(@club), headers: auth_headers(@moderator)
    end
    assert_response :forbidden
  end

  test "a token without write:clubs cannot join" do
    post api_v1_club_membership_url(@club), headers: auth_headers(@moderator, scopes: ["read:clubs"])
    assert_response :forbidden
  end
end
