json.partial! "api/v1/shelves/shelf", shelf: @shelf
json.books @shelf.shelf_books.includes(:book).order("books.title") do |shelf_book|
  json.shelf_book_id shelf_book.id
  json.partial! "api/v1/books/book", book: shelf_book.book
end
