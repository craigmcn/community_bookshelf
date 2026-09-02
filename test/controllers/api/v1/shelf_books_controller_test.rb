require "test_helper"

class Api::V1::ShelfBooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shelf = shelves(:one)
    @other_shelf = shelves(:two)
    @book_on_shelf = books(:one)
    @book_not_on_shelf = books(:two)
  end

  test "no token is rejected" do
    post api_v1_shelf_shelf_books_url(@shelf), params: {book_id: @book_not_on_shelf.id}
    assert_response :unauthorized
  end

  test "owner can add a book to their shelf" do
    assert_difference "@shelf.shelf_books.count" do
      post api_v1_shelf_shelf_books_url(@shelf), params: {book_id: @book_not_on_shelf.id}, headers: auth_headers(users(:member))
    end
    assert_response :created
    titles = JSON.parse(response.body)["books"].pluck("title")
    assert_includes titles, @book_not_on_shelf.title
  end

  test "adding a book already on the shelf is idempotent" do
    assert_no_difference "@shelf.shelf_books.count" do
      post api_v1_shelf_shelf_books_url(@shelf), params: {book_id: @book_on_shelf.id}, headers: auth_headers(users(:member))
    end
    assert_response :created
  end

  test "cannot add a book to another user's shelf" do
    post api_v1_shelf_shelf_books_url(@other_shelf), params: {book_id: @book_not_on_shelf.id}, headers: auth_headers(users(:member))
    assert_response :not_found
  end

  test "owner can remove a book from their shelf" do
    shelf_book = shelf_books(:one)
    assert_difference "@shelf.shelf_books.count", -1 do
      delete api_v1_shelf_shelf_book_url(@shelf, shelf_book), headers: auth_headers(users(:member))
    end
    assert_response :no_content
  end

  test "a read:shelves-only token cannot add a book" do
    post api_v1_shelf_shelf_books_url(@shelf), params: {book_id: @book_not_on_shelf.id}, headers: auth_headers(users(:member), scopes: ["read:shelves"])
    assert_response :forbidden
  end
end
