json.partial! "api/v1/buddy_reads/buddy_read", buddy_read: @buddy_read
json.messages @messages do |message|
  json.partial! "api/v1/buddy_reads/message", message: message
end
