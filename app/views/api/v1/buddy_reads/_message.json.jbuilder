json.id message.id
json.buddy_read_id message.buddy_read_id
json.user_id message.user_id
json.user do
  json.id message.user.id
  json.display_name message.user.display_name
end
json.body message.body
json.created_at message.created_at
