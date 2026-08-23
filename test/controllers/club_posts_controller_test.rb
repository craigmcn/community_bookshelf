require "test_helper"

class ClubPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: users(:member))
  end

  test "member can post to a club they belong to" do
    sign_in_as users(:member)
    post club_posts_url(@club), params: {club_post: {body: "Loving this so far!", spoiler: false}}

    assert_redirected_to club_url(@club)
    assert @club.club_posts.exists?(user: users(:member), body: "Loving this so far!")
  end

  test "non-member cannot post to a club" do
    sign_in_as users(:moderator)
    post club_posts_url(@club), params: {club_post: {body: "Hi!", spoiler: false}}

    assert_not @club.club_posts.exists?(user: users(:moderator))
  end

  test "post author can delete their own post" do
    post_record = ClubPost.create!(club: @club, user: users(:member), body: "Hi!")
    sign_in_as users(:member)

    delete club_post_url(@club, post_record)

    assert_not ClubPost.exists?(post_record.id)
  end

  test "moderator can delete another member's post" do
    post_record = ClubPost.create!(club: @club, user: users(:member), body: "Hi!")
    sign_in_as users(:moderator)

    delete club_post_url(@club, post_record)

    assert_not ClubPost.exists?(post_record.id)
  end
end
