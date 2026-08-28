require "test_helper"

class Api::V1::ReadingsBulkTest < ActionDispatch::IntegrationTest
  test "no token is rejected" do
    post bulk_api_v1_readings_url, params: {readings: []}
    assert_response :unauthorized
  end

  test "creates multiple readings in one request" do
    member = users(:member)

    assert_difference "Reading.count", 2 do
      post bulk_api_v1_readings_url,
        params: {readings: [{book_id: books(:one).id, status: "finished"}, {book_id: books(:two).id, status: "want_to_read"}]},
        headers: auth_headers(member),
        as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body["results"].size
    assert_equal ["created", "created"], body["results"].pluck("status")
    assert_equal member.id, Reading.last.user_id
  end

  test "a bad row fails independently without blocking the others" do
    member = users(:member)

    assert_difference "Reading.count", 1 do
      post bulk_api_v1_readings_url,
        params: {readings: [{book_id: books(:one).id, status: "finished"}, {book_id: nil, status: "finished"}]},
        headers: auth_headers(member),
        as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "created", body["results"][0]["status"]
    assert_equal "error", body["results"][1]["status"]
    assert body["results"][1]["errors"].present?
  end

  test "rejects a missing or empty readings array" do
    sign_in_headers = auth_headers(users(:member))

    post bulk_api_v1_readings_url, params: {}, headers: sign_in_headers, as: :json
    assert_response :unprocessable_content

    post bulk_api_v1_readings_url, params: {readings: []}, headers: sign_in_headers, as: :json
    assert_response :unprocessable_content
  end

  test "rejects a batch larger than the max size" do
    too_many = Array.new(Api::V1::ReadingsController::MAX_BULK_SIZE + 1) { {book_id: books(:one).id, status: "want_to_read"} }

    post bulk_api_v1_readings_url, params: {readings: too_many}, headers: auth_headers(users(:member)), as: :json

    assert_response :unprocessable_content
    assert_no_difference "Reading.count" do
      post bulk_api_v1_readings_url, params: {readings: too_many}, headers: auth_headers(users(:member)), as: :json
    end
  end
end
