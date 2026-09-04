require "test_helper"

class Api::V1::FavoriteGenresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @genre_tag = tags(:one)
  end

  test "no token is rejected" do
    get api_v1_favorite_genres_url
    assert_response :unauthorized
  end

  test "index lists only the token owner's favorite genres" do
    @member.favorite_genres.create!(tag: @genre_tag)
    users(:moderator).favorite_genres.create!(tag: tags(:two))

    get api_v1_favorite_genres_url, headers: auth_headers(@member)
    assert_response :success

    json = JSON.parse(response.body)["favorite_genres"]
    assert_equal 1, json.size
    assert_equal @genre_tag.id, json.first["tag_id"]
    assert_equal @genre_tag.name, json.first["tag"]["name"]
  end

  test "member can favorite a genre" do
    assert_difference "@member.favorite_genres.count" do
      post api_v1_favorite_genres_url, params: {tag_id: @genre_tag.id}, headers: auth_headers(@member)
    end
    assert_response :created
    assert_equal @genre_tag.id, JSON.parse(response.body)["tag_id"]
  end

  test "favoriting the same genre twice is idempotent" do
    @member.favorite_genres.create!(tag: @genre_tag)

    assert_no_difference "@member.favorite_genres.count" do
      post api_v1_favorite_genres_url, params: {tag_id: @genre_tag.id}, headers: auth_headers(@member)
    end
    assert_response :created
  end

  test "cannot favorite a non-genre tag" do
    mood_tag = Tag.create!(name: "cozy", category: "mood")

    assert_no_difference "@member.favorite_genres.count" do
      post api_v1_favorite_genres_url, params: {tag_id: mood_tag.id}, headers: auth_headers(@member)
    end
    assert_response :unprocessable_content
  end

  test "member can unfavorite a genre" do
    favorite_genre = @member.favorite_genres.create!(tag: @genre_tag)

    assert_difference "@member.favorite_genres.count", -1 do
      delete api_v1_favorite_genre_url(favorite_genre), headers: auth_headers(@member)
    end
    assert_response :no_content
  end

  test "member cannot unfavorite another user's favorite genre" do
    favorite_genre = users(:moderator).favorite_genres.create!(tag: @genre_tag)

    delete api_v1_favorite_genre_url(favorite_genre), headers: auth_headers(@member)
    assert_response :not_found
    assert FavoriteGenre.exists?(favorite_genre.id)
  end

  test "a read:favorite_genres-only token can list but not create" do
    get api_v1_favorite_genres_url, headers: auth_headers(@member, scopes: ["read:favorite_genres"])
    assert_response :success

    assert_no_difference "@member.favorite_genres.count" do
      post api_v1_favorite_genres_url, params: {tag_id: @genre_tag.id}, headers: auth_headers(@member, scopes: ["read:favorite_genres"])
    end
    assert_response :forbidden
  end
end
