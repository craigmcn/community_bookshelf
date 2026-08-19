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

  test "member can create a reading with a private review" do
    sign_in_as users(:member)
    assert_difference "Reading.count" do
      post readings_url, params: {reading: {book_id: books(:two).id, status: :reading, review: "Just for me", is_review_public: false}}
    end
    assert_not Reading.last.is_review_public?
  end

  test "member can toggle their review's privacy" do
    sign_in_as users(:member)
    patch reading_url(@reading), params: {reading: {status: @reading.status, book_id: @reading.book_id, is_review_public: false}}
    assert_not @reading.reload.is_review_public?
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

  test "member can set tracking fields on their own reading" do
    sign_in_as users(:member)
    patch reading_url(@reading), params: {reading: {
      book_id: @reading.book_id,
      status: :dnf,
      format: :ebook,
      started_on: "2026-01-01",
      finished_on: "2026-01-15",
      progress_percent: 42
    }}
    assert_redirected_to reading_url(@reading)
    @reading.reload
    assert_equal "dnf", @reading.status
    assert_equal "ebook", @reading.format
    assert_equal Date.new(2026, 1, 1), @reading.started_on
    assert_equal Date.new(2026, 1, 15), @reading.finished_on
    assert_equal 42, @reading.progress_percent
  end

  test "moderator can set tracking fields on any reading" do
    sign_in_as users(:moderator)
    patch reading_url(@reading), params: {reading: {book_id: @reading.book_id, status: :reading, progress_percent: 75}}
    assert_redirected_to reading_url(@reading)
    assert_equal 75, @reading.reload.progress_percent
  end

  test "guest cannot update tracking fields" do
    patch reading_url(@reading), params: {reading: {book_id: @reading.book_id, progress_percent: 75}}
    assert_redirected_to sign_in_path
    assert_nil @reading.reload.progress_percent
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
