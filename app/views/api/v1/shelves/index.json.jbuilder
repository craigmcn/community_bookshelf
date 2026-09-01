json.shelves @shelves do |shelf|
  json.partial! "api/v1/shelves/shelf", shelf: shelf
end
json.pagination do
  json.page @pagy.page
  json.pages @pagy.pages
  json.count @pagy.count
end
