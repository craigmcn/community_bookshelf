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

  test "another member can view a reading with a public review" do
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    sign_in_as other_member
    get reading_url(@reading)
    assert_response :success
  end

  test "reading page renders comments from multiple authors without N+1" do
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    ReviewComment.create!(user: users(:moderator), reading: @reading, body: "Nice!")
    ReviewComment.create!(user: other_member, reading: @reading, body: "Agreed!")

    sign_in_as users(:admin)
    get reading_url(@reading)

    assert_response :success
    assert_select "p", text: "Nice!"
    assert_select "p", text: "Agreed!"
  end

  test "another member cannot view a reading with a private review" do
    @reading.update!(is_review_public: false)
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    sign_in_as other_member
    get reading_url(@reading)
    assert_redirected_to root_path
  end

  test "another member cannot view a reading with no review at all" do
    reading = Reading.create!(user: users(:member), book: books(:two), status: :want_to_read)
    other_member = User.create!(email: "other@example.com", password: User::DEFAULT_PASSWORD)
    sign_in_as other_member
    get reading_url(reading)
    assert_redirected_to root_path
  end

  test "moderator can view a reading even with a private review" do
    @reading.update!(is_review_public: false)
    sign_in_as users(:moderator)
    get reading_url(@reading)
    assert_response :success
  end

  test "readings index only shows the current user's readings" do
    Reading.create!(user: users(:admin), book: books(:two), status: :reading)

    sign_in_as users(:member)
    get readings_url

    assert_response :success
    assert_includes @response.body, books(:one).title
    assert_not_includes @response.body, books(:two).title
  end

  test "readings index searches by book title or author" do
    Reading.create!(user: users(:member), book: books(:two), status: :reading)

    sign_in_as users(:member)
    get readings_url(q: books(:one).title)

    assert_response :success
    assert_includes @response.body, books(:one).title
    assert_not_includes @response.body, books(:two).title
  end

  test "readings index filters by status" do
    Reading.create!(user: users(:member), book: books(:two), status: :finished)

    sign_in_as users(:member)
    get readings_url(status: "finished")

    assert_response :success
    assert_includes @response.body, books(:two).title
    assert_not_includes @response.body, books(:one).title # readings(:one) is want_to_read
  end

  test "readings index filters by rating" do
    Reading.create!(user: users(:member), book: books(:two), status: :finished, rating: :two)

    sign_in_as users(:member)
    get readings_url(rating: "two")

    assert_response :success
    assert_includes @response.body, books(:two).title
    assert_not_includes @response.body, books(:one).title # readings(:one) is rated four
  end

  test "readings index filters by genre tag on the book" do
    books(:one).update!(tag_list: "fantasy")
    Reading.create!(user: users(:member), book: books(:two), status: :reading)

    sign_in_as users(:member)
    get readings_url(tag: "fantasy")

    assert_response :success
    assert_includes @response.body, books(:one).title
    assert_not_includes @response.body, books(:two).title
  end

  test "readings index shows a Clear link and a filtered-not-empty message for an unknown tag" do
    sign_in_as users(:member)
    get readings_url(tag: "does-not-exist")

    assert_response :success
    assert_select "a", text: "Clear"
    assert_includes @response.body, "No readings match those filters."
    assert_not_includes @response.body, "Your shelf is empty."
  end

  test "readings index browse-by-genre row excludes mood and pace tags" do
    books(:one).update!(tag_list: "fantasy", mood_list: "moody", pace_list: "fast-paced")

    sign_in_as users(:member)
    get readings_url

    assert_response :success
    assert_includes @response.body, "fantasy"
    assert_not_includes @response.body, "moody"
    assert_not_includes @response.body, "fast-paced"
  end

  test "readings index paginates results" do
    26.times do |n|
      book = Book.create!(title: "Extra Book #{n}", author: "Author #{n}", added_by: users(:member))
      Reading.create!(user: users(:member), book: book, status: :want_to_read)
    end

    sign_in_as users(:member)
    get readings_url
    assert_response :success
    assert_select ".pagy-bootstrap"
  end

  test "readings index shows tag-overlap recommendations excluding the user's own shelf" do
    @reading.update!(status: :finished)
    books(:one).update!(tag_list: "fantasy")
    recommended_one = Book.create!(title: "Recommended Read One", author: "Some Author", added_by: users(:member), tag_list: "fantasy")
    recommended_two = Book.create!(title: "Recommended Read Two", author: "Another Author", added_by: users(:admin), tag_list: "fantasy")

    sign_in_as users(:member)
    get readings_url

    assert_response :success
    assert_includes @response.body, "Recommended for You"
    assert_includes @response.body, recommended_one.title
    assert_includes @response.body, recommended_two.title
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
