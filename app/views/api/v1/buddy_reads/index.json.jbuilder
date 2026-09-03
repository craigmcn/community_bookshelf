json.buddy_reads @buddy_reads do |buddy_read|
  json.partial! "api/v1/buddy_reads/buddy_read", buddy_read: buddy_read
end
