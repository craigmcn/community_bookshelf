json.extract! shelf, :id, :name, :user_id, :created_at, :updated_at
json.book_count shelf.shelf_books.size
