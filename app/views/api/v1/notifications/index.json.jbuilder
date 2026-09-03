json.notifications @notifications do |notification|
  json.partial! "api/v1/notifications/notification", notification: notification
end
json.pagination do
  json.page @pagy.page
  json.pages @pagy.pages
  json.count @pagy.count
end
