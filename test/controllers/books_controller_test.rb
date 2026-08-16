require "test_helper"
require "webmock/minitest"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
  end

  # Public access
  test "anyone can view books index" do
    get books_url
    assert_response :success
  end

  test "anyone can view a book" do
    get book_url(@book)
    assert_response :success
  end

  # Auth wall
  test "guest is redirected to sign in for new" do
    get new_book_url
    assert_redirected_to sign_in_path
  end

  test "guest is redirected to sign in for create" do
    post books_url, params: {book: {title: "New", author: "Author", added_by_id: users(:member).id}}
    assert_redirected_to sign_in_path
  end

  # Member permissions
  test "member can view the new book form" do
    sign_in_as users(:member)
    get new_book_url
    assert_response :success
  end

  test "member can create a book" do
    sign_in_as users(:member)
    assert_difference "Book.count" do
      post books_url, params: {book: {title: "New Book", author: "Some Author", added_by_id: users(:member).id, cover_url: ""}}
    end
    assert_redirected_to book_url(Book.last)
  end

  test "member creating a book with an open_library_key pulls in description and subjects" do
    stub_request(:get, "https://openlibrary.org/works/OL468431W.json")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {description: "A novel about the American Dream.", subjects: ["Fiction", "Classics"]}.to_json
      )

    sign_in_as users(:member)
    assert_difference "Book.count" do
      post books_url, params: {book: {
        title: "New Book", author: "Some Author", added_by_id: users(:member).id, cover_url: "",
        open_library_key: "/works/OL468431W"
      }}
    end
    assert_redirected_to book_url(Book.last)

    book = Book.last
    assert_equal "A novel about the American Dream.", book.description
    assert_equal ["Fiction", "Classics"], book.subjects
  end

  test "open_library_key round-trips through a failed create so a retry can still fetch detail" do
    stub_request(:get, "https://openlibrary.org/works/OL468431W.json")
      .to_return(status: 200, headers: {"Content-Type" => "application/json"}, body: "{}")

    sign_in_as users(:member)
    assert_no_difference "Book.count" do
      post books_url, params: {book: {
        title: "", author: "Some Author", cover_url: "", open_library_key: "/works/OL468431W"
      }}
    end
    assert_response :unprocessable_content
    assert_select "input[name=?][value=?]", "book[open_library_key]", "/works/OL468431W"
  end

  test "member cannot update a book" do
    sign_in_as users(:member)
    patch book_url(@book), params: {book: {title: "Changed", author: @book.author, added_by_id: @book.added_by_id, cover_url: @book.cover_url}}
    assert_response :redirect
    assert_not_equal "Changed", @book.reload.title
  end

  test "member cannot destroy a book" do
    sign_in_as users(:member)
    assert_no_difference "Book.count" do
      delete book_url(@book)
    end
  end

  # Admin permissions
  test "admin can view the edit book form" do
    sign_in_as users(:admin)
    get edit_book_url(@book)
    assert_response :success
  end

  test "admin can update a book" do
    sign_in_as users(:admin)
    patch book_url(@book), params: {book: {title: "Updated", author: @book.author, added_by_id: @book.added_by_id, cover_url: @book.cover_url}}
    assert_redirected_to book_url(@book)
    assert_equal "Updated", @book.reload.title
  end

  test "admin can update a book's isbn, page_count, and published_on" do
    sign_in_as users(:admin)
    patch book_url(@book), params: {book: {
      title: @book.title, author: @book.author, added_by_id: @book.added_by_id, cover_url: @book.cover_url,
      isbn: "978-0743273565", page_count: 180, published_on: "1925-04-10"
    }}
    assert_redirected_to book_url(@book)
    @book.reload
    assert_equal "978-0743273565", @book.isbn
    assert_equal 180, @book.page_count
    assert_equal Date.new(1925, 4, 10), @book.published_on
  end

  test "admin can destroy a book" do
    sign_in_as users(:admin)
    assert_difference "Book.count", -1 do
      delete book_url(@book)
    end
    assert_redirected_to books_url
  end
end
