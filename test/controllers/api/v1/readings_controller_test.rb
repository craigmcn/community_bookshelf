require "test_helper"

class Api::V1::ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "no token is rejected" do
    get api_v1_readings_url
    assert_response :unauthorized
  end

  test "member's index only shows their own readings" do
    Reading.create!(user: users(:admin), book: books(:two), status: :reading)

    get api_v1_readings_url, headers: auth_headers(users(:member))

    assert_response :success
    book_ids = JSON.parse(response.body)["readings"].pluck("book_id")
    assert_includes book_ids, @reading.book_id
    assert_not_includes book_ids, books(:two).id
  end

  test "moderator's index shows every user's readings" do
    other_reading = Reading.create!(user: users(:admin), book: books(:two), status: :reading)

    get api_v1_readings_url, headers: auth_headers(users(:moderator))

    assert_response :success
    ids = JSON.parse(response.body)["readings"].pluck("id")
    assert_includes ids, @reading.id
    assert_includes ids, other_reading.id
  end

  test "member can show their own reading" do
    get api_v1_reading_url(@reading), headers: auth_headers(users(:member))
    assert_response :success
  end

  test "non-owner cannot show a reading with a private review" do
    @reading.update!(is_review_public: false)
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)

    get api_v1_reading_url(@reading), headers: auth_headers(other_member)

    assert_response :forbidden
  end

  test "member can create a reading" do
    assert_difference "Reading.count" do
      post api_v1_readings_url, params: {reading: {book_id: books(:two).id, status: "reading"}}, headers: auth_headers(users(:member))
    end
    assert_response :created
  end

  test "create with invalid params returns 422 with errors" do
    assert_no_difference "Reading.count" do
      post api_v1_readings_url, params: {reading: {book_id: books(:two).id, status: nil}}, headers: auth_headers(users(:member))
    end
    assert_response :unprocessable_content
    assert JSON.parse(response.body)["errors"].present?
  end

  test "member can update their own reading" do
    patch api_v1_reading_url(@reading), params: {reading: {book_id: @reading.book_id, status: "finished"}}, headers: auth_headers(users(:member))
    assert_response :success
    assert_equal "finished", @reading.reload.status
  end

  test "member cannot destroy a reading" do
    assert_no_difference "Reading.unscoped.count" do
      delete api_v1_reading_url(@reading), headers: auth_headers(users(:member))
    end
    assert_response :forbidden
    assert_nil @reading.reload.deleted_at
  end

  test "moderator destroy soft-deletes a reading" do
    assert_no_difference "Reading.unscoped.count" do
      delete api_v1_reading_url(@reading), headers: auth_headers(users(:moderator))
    end
    assert_response :no_content
    assert_not_nil @reading.reload.deleted_at
  end
end
