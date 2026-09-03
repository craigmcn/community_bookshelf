json.extract! buddy_read, :id, :book_id, :initiator_id, :partner_id, :status, :created_at, :updated_at
json.book do
  json.id buddy_read.book.id
  json.title buddy_read.book.title
end
json.initiator do
  json.id buddy_read.initiator.id
  json.display_name buddy_read.initiator.display_name
end
json.partner do
  json.id buddy_read.partner.id
  json.display_name buddy_read.partner.display_name
end
