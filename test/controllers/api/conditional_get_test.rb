require "test_helper"

class Api::ConditionalGetTest < ActionDispatch::IntegrationTest
  test "book show returns an ETag and 304s on a matching If-None-Match" do
    get api_v1_book_url(books(:one)), headers: auth_headers(users(:member))
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_book_url(books(:one)), headers: auth_headers(users(:member)).merge("If-None-Match" => etag)
    assert_response :not_modified
  end

  test "book show 304 flips back to 200 once the book changes" do
    book = books(:one)
    get api_v1_book_url(book), headers: auth_headers(users(:member))
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    book.update!(title: "A New Title")

    get api_v1_book_url(book), headers: auth_headers(users(:member)).merge("If-None-Match" => etag)
    assert_response :success
  end

  test "books index returns an ETag and 304s on a matching If-None-Match" do
    get api_v1_books_url, headers: auth_headers(users(:member))
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_books_url, headers: auth_headers(users(:member)).merge("If-None-Match" => etag)
    assert_response :not_modified
  end

  test "reading show returns an ETag and 304s on a matching If-None-Match" do
    reading = readings(:one)
    get api_v1_reading_url(reading), headers: auth_headers(reading.user)
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_reading_url(reading), headers: auth_headers(reading.user).merge("If-None-Match" => etag)
    assert_response :not_modified
  end

  test "reading show 304 flips back to 200 when only the nested book changes" do
    reading = readings(:one)
    get api_v1_reading_url(reading), headers: auth_headers(reading.user)
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    # The reading itself is untouched — only its nested book changes. show
    # renders that book inline (see show.json.jbuilder), so a client's
    # cached copy is now stale even though the reading's own updated_at
    # didn't move.
    reading.book.update!(title: "A Completely Different Title")

    get api_v1_reading_url(reading), headers: auth_headers(reading.user).merge("If-None-Match" => etag)
    assert_response :success
  end

  test "readings index returns an ETag and 304s on a matching If-None-Match" do
    sign_in_headers = auth_headers(users(:member))
    get api_v1_readings_url, headers: sign_in_headers
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_readings_url, headers: sign_in_headers.merge("If-None-Match" => etag)
    assert_response :not_modified
  end

  # The index nests each book, so a book edit alone must not 304 a stale cached copy.
  test "readings index 304 flips back to 200 when only a nested book changes" do
    reading = readings(:one)
    sign_in_headers = auth_headers(reading.user)
    get api_v1_readings_url, headers: sign_in_headers
    etag = response.headers["ETag"]

    reading.book.update!(title: "A Completely Different Title")

    get api_v1_readings_url, headers: sign_in_headers.merge("If-None-Match" => etag)
    assert_response :success
  end

  # The ETag must cover each row and the total, or pagination and removed rows go stale.
  test "readings index 304 flips back to 200 when a reading on a later page is removed" do
    member = users(:member)
    extra = 20.times.map { Reading.create!(user: member, book: books(:two), status: :want_to_read) }
    Reading.where(id: extra.first.id).update_all(updated_at: 1.year.ago)
    headers = auth_headers(member)
    get api_v1_readings_url, params: {mine: "true"}, headers: headers
    etag = response.headers["ETag"]
    assert_equal 2, JSON.parse(response.body).dig("pagination", "pages")

    delete api_v1_reading_url(extra.first), headers: headers
    get api_v1_readings_url, params: {mine: "true"}, headers: headers.merge("If-None-Match" => etag)

    assert_response :success
    assert_equal 1, JSON.parse(response.body).dig("pagination", "pages")
  end

  # A full page: the next row slides in, so the page's row count and newest updated_at stay the same.
  test "readings index 304 flips back to 200 when a reading mid-page is removed" do
    member = users(:member)
    readings = 25.times.map { Reading.create!(user: member, book: books(:two), status: :want_to_read) }
    headers = auth_headers(member)
    get api_v1_readings_url, params: {book_id: books(:two).id}, headers: headers
    etag = response.headers["ETag"]

    delete api_v1_reading_url(readings[-3]), headers: headers
    get api_v1_readings_url, params: {book_id: books(:two).id}, headers: headers.merge("If-None-Match" => etag)

    assert_response :success
    assert_not_includes JSON.parse(response.body)["readings"].pluck("id"), readings[-3].id
  end

  test "books index 304 flips back to 200 when a book on a later page is deleted" do
    19.times { |i| Book.create!(title: "Zzz #{i}", author: "Someone", added_by: users(:member)) }
    get api_v1_books_url
    etag = response.headers["ETag"]
    assert_equal 2, JSON.parse(response.body).dig("pagination", "pages")

    Book.find_by!(title: "Zzz 9").destroy! # sorts last, so it's on page 2
    get api_v1_books_url, headers: {"If-None-Match" => etag}

    assert_response :success
    assert_equal 1, JSON.parse(response.body).dig("pagination", "pages")
  end

  test "book show 304 flips back to 200 when only its tags change" do
    book = books(:one)
    get api_v1_book_url(book)
    etag = response.headers["ETag"]

    book.update!(tag_list: "classic")
    get api_v1_book_url(book), headers: {"If-None-Match" => etag}

    assert_response :success
    assert_equal "classic", JSON.parse(response.body)["tag_list"]
  end
end
