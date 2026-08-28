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
    etag = response.headers["ETag"]

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

  test "readings index returns an ETag and 304s on a matching If-None-Match" do
    sign_in_headers = auth_headers(users(:member))
    get api_v1_readings_url, headers: sign_in_headers
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?

    get api_v1_readings_url, headers: sign_in_headers.merge("If-None-Match" => etag)
    assert_response :not_modified
  end
end
