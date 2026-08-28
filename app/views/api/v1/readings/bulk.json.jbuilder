json.results @results do |result|
  json.index result[:index]
  json.status result[:status]

  if result[:status] == "created"
    json.reading do
      json.partial! "api/v1/readings/reading", reading: result[:reading]
    end
  else
    json.errors result[:errors]
  end
end
