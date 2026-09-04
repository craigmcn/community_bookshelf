json.extract! review_comment, :id, :reading_id, :user_id, :body, :created_at
json.user do
  json.id review_comment.user.id
  json.display_name review_comment.user.display_name
end
