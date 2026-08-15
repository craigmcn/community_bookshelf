class OpenLibraryService
  BASE_URL = "https://openlibrary.org"
  COVER_URL = "https://covers.openlibrary.org/b/id/%s-M.jpg"
  MAX_SUBJECTS = 10
  WORK_KEY_PATTERN = %r{\A/works/OL\d+W\z}

  def self.search(query)
    return [] if query.blank?

    conn = Faraday.new(url: BASE_URL)
    response = conn.get("/search.json", {q: query, limit: 10, fields: "title,author_name,cover_i,key"})
    data = JSON.parse(response.body)

    data["docs"].filter_map do |doc|
      next if doc["title"].blank?

      {
        title: doc["title"],
        author: Array(doc["author_name"]).first || "Unknown",
        cover_url: doc["cover_i"] ? format(COVER_URL, doc["cover_i"]) : nil,
        open_library_key: doc["key"]
      }
    end
  rescue Faraday::Error
    []
  end

  def self.work_detail(key)
    return {} unless key.is_a?(String) && key.match?(WORK_KEY_PATTERN)

    conn = Faraday.new(url: BASE_URL)
    response = conn.get("#{key}.json")
    data = JSON.parse(response.body)

    description = data["description"]
    description = description["value"] if description.is_a?(Hash)

    {
      description: description,
      subjects: Array(data["subjects"]).first(MAX_SUBJECTS)
    }
  rescue Faraday::Error, JSON::ParserError
    {}
  end
end
