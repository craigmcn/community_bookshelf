json.extract! notification, :id, :notification_type, :read_at, :created_at
json.message notification.message
json.actor do
  json.id notification.actor.id
  json.display_name notification.actor.display_name
end
json.target_type notification.target_type
json.target_id notification.target_id
