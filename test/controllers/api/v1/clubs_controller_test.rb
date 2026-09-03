require "test_helper"

class Api::V1::ClubsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @moderator = users(:moderator)
    @club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: @member)
  end

  test "no token is rejected" do
    get api_v1_clubs_url
    assert_response :unauthorized
  end

  test "any signed-in token can list clubs" do
    get api_v1_clubs_url, headers: auth_headers(@moderator)
    assert_response :success
    assert_equal Club.count, JSON.parse(response.body)["clubs"].size
  end

  test "index shows accurate member counts" do
    @club.club_memberships.create!(user: @moderator)

    get api_v1_clubs_url, headers: auth_headers(@moderator)
    club_json = JSON.parse(response.body)["clubs"].find { |c| c["id"] == @club.id }
    assert_equal 2, club_json["member_count"]
  end

  test "any signed-in token can show a club" do
    get api_v1_club_url(@club), headers: auth_headers(@moderator)
    assert_response :success
    assert_equal @club.name, JSON.parse(response.body)["name"]
  end

  test "show hides a spoiler post's body from a viewer who hasn't finished the book" do
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    @club.club_memberships.create!(user: other_member)
    ClubPost.create!(club: @club, user: @member, body: "Twist!", spoiler: true)

    get api_v1_club_url(@club), headers: auth_headers(other_member)
    post_json = JSON.parse(response.body)["club_posts"].first
    assert post_json["hidden"]
    assert_nil post_json["body"]
  end

  test "show reveals a spoiler post's body to its own author" do
    ClubPost.create!(club: @club, user: @member, body: "Twist!", spoiler: true)

    get api_v1_club_url(@club), headers: auth_headers(@member)
    post_json = JSON.parse(response.body)["club_posts"].first
    assert_not post_json["hidden"]
    assert_equal "Twist!", post_json["body"]
  end

  test "show reveals a spoiler post's body to a moderator regardless of their reading status" do
    ClubPost.create!(club: @club, user: @member, body: "Twist!", spoiler: true)

    get api_v1_club_url(@club), headers: auth_headers(@moderator)
    post_json = JSON.parse(response.body)["club_posts"].first
    assert_not post_json["hidden"]
    assert_equal "Twist!", post_json["body"]
  end

  test "member can create a club and is auto-joined" do
    assert_difference "Club.count" do
      post api_v1_clubs_url, params: {club: {name: "Fantasy Fans", book_id: books(:two).id}}, headers: auth_headers(@member)
    end
    assert_response :created
    club = Club.last
    assert_equal @member, club.created_by
    assert club.member?(@member)
  end

  test "creator can update their own club" do
    patch api_v1_club_url(@club), params: {club: {name: "Renamed"}}, headers: auth_headers(@member)
    assert_response :success
    assert_equal "Renamed", @club.reload.name
  end

  test "a non-creator, non-moderator cannot update the club" do
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    patch api_v1_club_url(@club), params: {club: {name: "Renamed"}}, headers: auth_headers(other_member)
    assert_response :forbidden
    assert_not_equal "Renamed", @club.reload.name
  end

  test "a moderator can update someone else's club" do
    patch api_v1_club_url(@club), params: {club: {name: "Renamed"}}, headers: auth_headers(@moderator)
    assert_response :success
    assert_equal "Renamed", @club.reload.name
  end

  test "creator can destroy their own club" do
    assert_difference "Club.count", -1 do
      delete api_v1_club_url(@club), headers: auth_headers(@member)
    end
    assert_response :no_content
  end

  test "a read:clubs-only token can list clubs but not create one" do
    get api_v1_clubs_url, headers: auth_headers(@member, scopes: ["read:clubs"])
    assert_response :success

    assert_no_difference "Club.count" do
      post api_v1_clubs_url, params: {club: {name: "Fantasy Fans", book_id: books(:two).id}}, headers: auth_headers(@member, scopes: ["read:clubs"])
    end
    assert_response :forbidden
  end
end
