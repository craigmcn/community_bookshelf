json.id favorite_genre.id
json.tag_id favorite_genre.tag_id
json.tag do
  json.partial! "api/v1/tags/tag", tag: favorite_genre.tag
end
json.created_at favorite_genre.created_at
