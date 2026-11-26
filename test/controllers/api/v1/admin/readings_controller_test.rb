require "test_helper"

class Api::V1::Admin::ReadingsControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors get a 401" do
    get api_v1_admin_readings_url
    assert_response :unauthorized
  end

  test "members get a 403" do
    sign_in_as users(:member)
    get api_v1_admin_readings_url
    assert_response :forbidden
  end

  test "a moderator's API token is refused" do
    get api_v1_admin_readings_url, headers: auth_headers(users(:moderator))
    assert_response :forbidden
  end

  test "a moderator lists reviewed readings, newest first, including deleted ones" do
    deleted = Reading.create!(user: users(:admin), book: books(:two), status: :finished, review: "Not for me.", rating: :two)
    deleted.soft_delete
    Reading.create!(user: users(:admin), book: books(:two), status: :reading)

    sign_in_as users(:moderator)
    get api_v1_admin_readings_url

    assert_response :success
    readings = JSON.parse(response.body)["readings"]
    assert_equal [deleted.id, readings(:one).id].sort, readings.pluck("id").sort
    row = readings.find { |reading| reading["id"] == deleted.id }
    assert_equal ["Not for me.", "finished", "two"], row.values_at("review", "status", "rating")
    assert row["deleted_at"].present?
    assert_equal({"id" => users(:admin).id, "email" => "admin@example.com"}, row["user"])
    assert_equal({"id" => books(:two).id, "title" => "1984", "author" => "George Orwell"}, row["book"])
  end

  test "ties on updated_at break by newest id" do
    newer = Reading.create!(user: users(:admin), book: books(:two), status: :finished, review: "Fine.")
    Reading.update_all(updated_at: 1.hour.ago)

    sign_in_as users(:moderator)
    get api_v1_admin_readings_url

    ids = JSON.parse(response.body)["readings"].pluck("id")
    assert_equal ids.sort.reverse, ids
    assert_includes ids, newer.id
  end
end
