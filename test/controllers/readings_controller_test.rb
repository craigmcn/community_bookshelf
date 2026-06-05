require "test_helper"

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "guest is redirected to sign in" do
    get readings_url
    assert_redirected_to sign_in_path
  end

  test "member can view their readings" do
    sign_in_as users(:member)
    get readings_url
    assert_response :success
  end

  test "member can create a reading" do
    sign_in_as users(:member)
    assert_difference "Reading.count" do
      post readings_url, params: { reading: { user_id: users(:member).id, book_id: books(:two).id, status: :reading } }
    end
    assert_redirected_to reading_url(Reading.last)
  end

  test "member can update their own reading" do
    sign_in_as users(:member)
    patch reading_url(@reading), params: { reading: { status: :finished, user_id: @reading.user_id, book_id: @reading.book_id } }
    assert_redirected_to reading_url(@reading)
    assert_equal "finished", @reading.reload.status
  end

  test "member cannot destroy a reading" do
    sign_in_as users(:member)
    assert_no_difference "Reading.count" do
      delete reading_url(@reading)
    end
    assert_nil @reading.reload.deleted_at
  end

  test "moderator can soft-delete a reading" do
    sign_in_as users(:moderator)
    assert_no_difference "Reading.count" do
      delete reading_url(@reading)
    end
    assert_redirected_to readings_url
    assert_not_nil @reading.reload.deleted_at
  end
end
