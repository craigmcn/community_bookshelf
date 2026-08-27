json.partial! "api/v1/readings/reading", reading: @reading
json.book do
  json.partial! "api/v1/books/book", book: @reading.book
end
