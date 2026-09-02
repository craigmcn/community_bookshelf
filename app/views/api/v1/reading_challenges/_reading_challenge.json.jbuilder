json.extract! reading_challenge, :id, :user_id, :year, :goal, :created_at, :updated_at
json.books_finished_count reading_challenge.books_finished_count
json.progress_percent reading_challenge.progress_percent
json.completed reading_challenge.completed?
