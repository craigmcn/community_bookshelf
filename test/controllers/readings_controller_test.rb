require "test_helper"

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "should get index" do
    get readings_url
    assert_response :success
  end

  test "should get new" do
    get new_reading_url
    assert_response :success
  end

  test "should create reading" do
    assert_difference("Reading.count") do
      post readings_url, params: { reading: { book_id: @reading.book_id, rating: @reading.rating, review: @reading.review, status: @reading.status, user_id: @reading.user_id } }
    end

    assert_redirected_to reading_url(Reading.last)
  end

  test "should show reading" do
    get reading_url(@reading)
    assert_response :success
  end

  test "should get edit" do
    get edit_reading_url(@reading)
    assert_response :success
  end

  test "should update reading" do
    patch reading_url(@reading), params: { reading: { book_id: @reading.book_id, rating: @reading.rating, review: @reading.review, status: @reading.status, user_id: @reading.user_id } }
    assert_redirected_to reading_url(@reading)
  end

  test "should destroy reading" do
    assert_difference("Reading.count", -1) do
      delete reading_url(@reading)
    end

    assert_redirected_to readings_url
  end
end
