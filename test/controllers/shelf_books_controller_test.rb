require "test_helper"

class ShelfBooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shelf = shelves(:one) # owned by member, already has books(:one)
  end

  test "guest is redirected to sign in" do
    post shelf_shelf_books_url(@shelf), params: {book_id: books(:two).id}
    assert_redirected_to sign_in_path
  end

  test "member can add a book to their own shelf" do
    sign_in_as users(:member)
    assert_difference "@shelf.shelf_books.count" do
      post shelf_shelf_books_url(@shelf), params: {book_id: books(:two).id}
    end
    assert_redirected_to @shelf
  end

  test "adding a book already on the shelf is a no-op" do
    sign_in_as users(:member)
    assert_no_difference "@shelf.shelf_books.count" do
      post shelf_shelf_books_url(@shelf), params: {book_id: books(:one).id}
    end
    assert_redirected_to @shelf
  end

  test "member cannot add a book to another user's shelf" do
    sign_in_as users(:member)
    post shelf_shelf_books_url(shelves(:two)), params: {book_id: books(:two).id}
    assert_response :not_found
  end

  test "member can remove a book from their own shelf" do
    sign_in_as users(:member)
    shelf_book = shelf_books(:one)
    assert_difference "@shelf.shelf_books.count", -1 do
      delete shelf_shelf_book_url(@shelf, shelf_book)
    end
    assert_redirected_to @shelf
  end

  test "member cannot remove a book from another user's shelf" do
    sign_in_as users(:member)
    delete shelf_shelf_book_url(shelves(:two), shelf_books(:one))
    assert_response :not_found
  end
end
