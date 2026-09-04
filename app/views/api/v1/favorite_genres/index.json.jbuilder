json.favorite_genres @favorite_genres do |favorite_genre|
  json.partial! "api/v1/favorite_genres/favorite_genre", favorite_genre: favorite_genre
end
