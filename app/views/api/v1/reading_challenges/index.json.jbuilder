json.reading_challenges @reading_challenges do |reading_challenge|
  json.partial! "api/v1/reading_challenges/reading_challenge", reading_challenge: reading_challenge
end
