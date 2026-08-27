json.readings @readings do |reading|
  json.partial! "api/v1/readings/reading", reading: reading
end
json.pagination do
  json.page @pagy.page
  json.pages @pagy.pages
  json.count @pagy.count
end
