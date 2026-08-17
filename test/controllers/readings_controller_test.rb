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
      post readings_url, params: {reading: {book_id: books(:two).id, status: :reading}}
    end
    assert_redirected_to reading_url(Reading.last)
  end

  test "member can start a re-read of a book they've already read" do
    sign_in_as users(:member)
    # readings(:one) is already a member reading of books(:one); confirm a second,
    # independent reading record for the same user/book pair can be created.
    assert_difference "Reading.count" do
      post readings_url, params: {reading: {book_id: @reading.book_id, status: :want_to_read}}
    end
    new_reading = Reading.last
    assert_redirected_to reading_url(new_reading)
    assert_equal @reading.book_id, new_reading.book_id
    assert_equal users(:member).id, new_reading.user_id
    assert_not_equal @reading.id, new_reading.id
  end

  test "member can update their own reading" do
    sign_in_as users(:member)
    patch reading_url(@reading), params: {reading: {status: :finished, book_id: @reading.book_id}}
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
    assert_no_difference "Reading.unscoped.count" do
      delete reading_url(@reading)
    end
    assert_redirected_to readings_url
    assert_not_nil @reading.reload.deleted_at
  end
end
