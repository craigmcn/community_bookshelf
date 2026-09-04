require "test_helper"

class Api::V1::ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "no token is rejected" do
    get api_v1_readings_url
    assert_response :unauthorized
  end

  test "garbage token is rejected" do
    get api_v1_readings_url, headers: {"Authorization" => "Bearer not-a-real-token"}
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

  test "a read:readings-only token cannot create a reading" do
    assert_no_difference "Reading.unscoped.count" do
      post api_v1_readings_url, params: {reading: {book_id: books(:two).id, status: "want_to_read"}}, headers: auth_headers(users(:member), scopes: ["read:readings"])
    end
    assert_response :forbidden
  end

  test "a write:readings-only token cannot list readings" do
    get api_v1_readings_url, headers: auth_headers(users(:member), scopes: ["write:readings"])
    assert_response :forbidden
  end

  # No new/edit actions exist for this JSON API. /new (a 2-segment path)
  # falls through to the show route with id="new" and 404s via the
  # controller's generic not-found handler; /:id/edit has no matching
  # route at all now that edit is gone, so it 404s at the routing layer
  # before ever reaching the controller. Neither raises the unhandled
  # ActionView::MissingTemplate this used to produce.
  test "GET /new and /:id/edit have no route of their own" do
    get "/api/v1/readings/new", headers: auth_headers(users(:member))
    assert_response :not_found

    get "/api/v1/readings/#{@reading.id}/edit", headers: auth_headers(users(:member))
    assert_response :not_found
  end
end
