require "test_helper"

class Api::V1::StatsControllerTest < ActionDispatch::IntegrationTest
  test "no token is rejected" do
    get api_v1_stats_url
    assert_response :unauthorized
  end

  test "member with no finished readings gets empty/zeroed stats" do
    get api_v1_stats_url, headers: auth_headers(users(:member))
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal [], json["genre_breakdown"]
    assert_equal 12, json["books_finished_by_month"].size
    assert json["books_finished_by_month"].all? { |row| row["count"].zero? }
    assert_equal 12, json["pages_read_by_month"].size
    assert json["pages_read_by_month"].all? { |row| row["pages"].zero? }
  end

  test "member's stats reflect their own finished, tagged, paged books" do
    tag = tags(:one)
    book = books(:one)
    book.update!(page_count: 300)
    Reading.create!(user: users(:member), book: book, status: :finished, finished_on: Date.current)

    get api_v1_stats_url, headers: auth_headers(users(:member))
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal [{"genre" => tag.name, "count" => 1}], json["genre_breakdown"]
    current_month_row = json["books_finished_by_month"].find { |row| row["month"] == Date.current.beginning_of_month.iso8601 }
    assert_equal 1, current_month_row["count"]
    current_pages_row = json["pages_read_by_month"].find { |row| row["month"] == Date.current.beginning_of_month.iso8601 }
    assert_equal 300, current_pages_row["pages"]
  end

  test "stats only reflect the token owner's readings, not another user's" do
    tag = tags(:one)
    book = books(:one)
    Reading.create!(user: users(:moderator), book: book, status: :finished, finished_on: Date.current)

    get api_v1_stats_url, headers: auth_headers(users(:member))
    assert_response :success

    json = JSON.parse(response.body)
    assert_not_includes json["genre_breakdown"].pluck("genre"), tag.name
  end

  test "a token without read:stats is rejected" do
    get api_v1_stats_url, headers: auth_headers(users(:member), scopes: ["read:books"])
    assert_response :forbidden
  end
end
