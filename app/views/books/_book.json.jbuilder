json.extract! book, :id, :title, :author, :cover_url, :added_by_id, :created_at, :updated_at
json.url book_url(book, format: :json)
