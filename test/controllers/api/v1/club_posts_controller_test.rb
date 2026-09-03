require "test_helper"

class Api::V1::ClubPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @moderator = users(:moderator)
    @club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: @member)
  end

  test "no token is rejected" do
    post api_v1_club_posts_url(@club), params: {club_post: {body: "Hi!"}}
    assert_response :unauthorized
  end

  test "member can post to a club they belong to" do
    assert_difference "@club.club_posts.count" do
      post api_v1_club_posts_url(@club), params: {club_post: {body: "Loving this so far!", spoiler: false}}, headers: auth_headers(@member)
    end
    assert_response :created
    assert_equal "Loving this so far!", JSON.parse(response.body)["body"]
  end

  test "non-member cannot post to a club" do
    assert_no_difference "@club.club_posts.count" do
      post api_v1_club_posts_url(@club), params: {club_post: {body: "Hi!", spoiler: false}}, headers: auth_headers(@moderator)
    end
    assert_response :forbidden
  end

  test "post author can delete their own post" do
    post_record = ClubPost.create!(club: @club, user: @member, body: "Hi!")

    assert_difference "ClubPost.count", -1 do
      delete api_v1_club_post_url(@club, post_record), headers: auth_headers(@member)
    end
    assert_response :no_content
  end

  test "moderator can delete another member's post" do
    post_record = ClubPost.create!(club: @club, user: @member, body: "Hi!")

    assert_difference "ClubPost.count", -1 do
      delete api_v1_club_post_url(@club, post_record), headers: auth_headers(@moderator)
    end
    assert_response :no_content
  end

  test "another member cannot delete someone else's post" do
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    @club.club_memberships.create!(user: other_member)
    post_record = ClubPost.create!(club: @club, user: @member, body: "Hi!")

    assert_no_difference "ClubPost.count" do
      delete api_v1_club_post_url(@club, post_record), headers: auth_headers(other_member)
    end
    assert_response :forbidden
  end

  test "a token without write:clubs cannot post" do
    post api_v1_club_posts_url(@club), params: {club_post: {body: "Hi!"}}, headers: auth_headers(@member, scopes: ["read:clubs"])
    assert_response :forbidden
  end
end
