json.books @books do |book|
  json.partial! "api/v1/books/book", book: book
end
json.pagination do
  json.page @pagy.page
  json.pages @pagy.pages
  json.count @pagy.count
end
