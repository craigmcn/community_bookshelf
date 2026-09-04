require "test_helper"
require "webmock/minitest"

class Api::V1::BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
  end

  test "no token is rejected" do
    get api_v1_books_url
    assert_response :unauthorized
  end

  test "garbage token is rejected" do
    get api_v1_books_url, headers: {"Authorization" => "Bearer not-a-real-token"}
    assert_response :unauthorized
  end

  test "valid token can list books" do
    get api_v1_books_url, headers: auth_headers(users(:member))
    assert_response :success
    assert_equal Book.count, JSON.parse(response.body)["books"].size
  end

  test "valid token can show a book" do
    get api_v1_book_url(@book), headers: auth_headers(users(:member))
    assert_response :success
    assert_equal @book.title, JSON.parse(response.body)["title"]
  end

  test "member can create a book" do
    assert_difference "Book.count" do
      post api_v1_books_url, params: {book: {title: "New Book", author: "Some Author"}}, headers: auth_headers(users(:member))
    end
    assert_response :created
  end

  test "member creating a book with an open_library_key pulls in description and subjects" do
    stub_request(:get, "https://openlibrary.org/works/OL468431W.json")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {description: "A novel about the American Dream.", subjects: ["Fiction", "Classics"]}.to_json
      )

    post api_v1_books_url, params: {book: {title: "New Book", author: "Some Author", open_library_key: "/works/OL468431W"}},
      headers: auth_headers(users(:member))

    assert_response :created
    book = Book.last
    assert_equal "A novel about the American Dream.", book.description
    assert_equal ["Fiction", "Classics"], book.subjects
  end

  test "create with invalid params returns 422 with errors" do
    assert_no_difference "Book.count" do
      post api_v1_books_url, params: {book: {title: ""}}, headers: auth_headers(users(:member))
    end
    assert_response :unprocessable_content
    assert JSON.parse(response.body)["errors"].present?
  end

  test "member cannot update a book" do
    patch api_v1_book_url(@book), params: {book: {title: "Changed"}}, headers: auth_headers(users(:member))
    assert_response :forbidden
    assert_not_equal "Changed", @book.reload.title
  end

  test "member cannot destroy a book" do
    assert_no_difference "Book.count" do
      delete api_v1_book_url(@book), headers: auth_headers(users(:member))
    end
    assert_response :forbidden
  end

  test "moderator can update a book" do
    patch api_v1_book_url(@book), params: {book: {title: "Updated"}}, headers: auth_headers(users(:moderator))
    assert_response :success
    assert_equal "Updated", @book.reload.title
  end

  test "admin can destroy a book" do
    assert_difference "Book.count", -1 do
      delete api_v1_book_url(@book), headers: auth_headers(users(:admin))
    end
    assert_response :no_content
  end

  test "a read:books-only token can list books" do
    get api_v1_books_url, headers: auth_headers(users(:member), scopes: ["read:books"])
    assert_response :success
  end

  test "a read:books-only token cannot create a book" do
    assert_no_difference "Book.count" do
      post api_v1_books_url, params: {book: {title: "New Book", author: "Some Author"}}, headers: auth_headers(users(:member), scopes: ["read:books"])
    end
    assert_response :forbidden
  end

  test "a write:books-only token cannot list books" do
    get api_v1_books_url, headers: auth_headers(users(:member), scopes: ["write:books"])
    assert_response :forbidden
  end

  # No new/edit actions exist for this JSON API — /new and /:id/edit should
  # 404 as "book not found" (falling through to show/:id), not raise an
  # unhandled ActionView::MissingTemplate.
  test "GET /new and /:id/edit have no route of their own" do
    get "/api/v1/books/new", headers: auth_headers(users(:member))
    assert_response :not_found

    get "/api/v1/books/#{@book.id}/edit", headers: auth_headers(users(:member))
    assert_response :not_found
  end
end
