json.total_users @total_users
json.total_books @total_books
json.total_readings @total_readings
json.popular_books @popular_books do |book|
  json.extract! book, :id, :title, :author, :readings_count
end
