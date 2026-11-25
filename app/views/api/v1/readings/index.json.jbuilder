json.readings @readings do |reading|
  json.partial! "api/v1/readings/reading", reading: reading
  # The summary skips the tag lists, which each run their own query per book.
  json.book do
    json.partial! "api/v1/shelves/book_summary", book: reading.book
  end
end
json.pagination do
  json.page @pagy.page
  json.pages @pagy.pages
  json.count @pagy.count
end
