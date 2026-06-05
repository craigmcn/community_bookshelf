class OpenLibraryService
  BASE_URL = "https://openlibrary.org"
  COVER_URL = "https://covers.openlibrary.org/b/id/%s-M.jpg"

  def self.search(query)
    return [] if query.blank?

    conn = Faraday.new(url: BASE_URL)
    response = conn.get("/search.json", { q: query, limit: 10, fields: "title,author_name,cover_i" })
    data = JSON.parse(response.body)

    data["docs"].filter_map do |doc|
      next unless doc["title"].present?

      {
        title: doc["title"],
        author: Array(doc["author_name"]).first || "Unknown",
        cover_url: doc["cover_i"] ? format(COVER_URL, doc["cover_i"]) : nil
      }
    end
  rescue Faraday::Error
    []
  end
end
