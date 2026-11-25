json.readings @readings do |reading|
  json.extract! reading, :id, :status, :rating, :review, :deleted_at, :updated_at
  json.user do
    json.extract! reading.user, :id, :email
  end
  json.book do
    json.extract! reading.book, :id, :title, :author
  end
end
