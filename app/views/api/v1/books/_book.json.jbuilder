json.extract! book, :id, :title, :author, :isbn, :cover_url, :page_count, :published_on,
  :description, :subjects, :series_id, :series_position, :added_by_id, :created_at, :updated_at
json.tag_list book.tag_list
json.mood_list book.mood_list
json.pace_list book.pace_list
