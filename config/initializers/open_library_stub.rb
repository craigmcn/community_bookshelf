if ENV["OPEN_LIBRARY_STUB"] == "1"
  require "webmock"
  WebMock.enable!
  WebMock.allow_net_connect!

  webmock = Object.new.extend(WebMock::API)

  webmock.stub_request(:get, /openlibrary\.org\/search\.json/).to_return do |request|
    query = Rack::Utils.parse_nested_query(request.uri.query)["q"].to_s.downcase

    docs = [
      {title: "The Hobbit", author_name: ["J.R.R. Tolkien"], cover_i: 1, key: "/works/OL27448W"},
      {title: "The Great Gatsby", author_name: ["F. Scott Fitzgerald"], cover_i: 2, key: "/works/OL468431W"},
      {title: "1984", author_name: ["George Orwell"], cover_i: 3, key: "/works/OL1168083W"},
      {title: "Harry Potter and the Chamber of Secrets", author_name: ["J.K. Rowling"], cover_i: 4, key: "/works/OL82586W"},
      {title: "The Silmarillion", author_name: ["J.R.R. Tolkien"], cover_i: 5, key: "/works/OL262758W"}
    ].select { |doc| doc[:title].downcase.include?(query) }

    {status: 200, headers: {"Content-Type" => "application/json"}, body: {docs: docs}.to_json}
  end

  work_details = {
    "/works/OL27448W" => {description: "A hobbit's unexpected adventure.", subjects: ["Fantasy fiction"]},
    "/works/OL468431W" => {description: "A novel about the American Dream.", subjects: ["Fiction", "Classics"]},
    "/works/OL1168083W" => {description: "A dystopian social science fiction novel.", subjects: ["Dystopias"]},
    "/works/OL82586W" => {description: "Harry's second year at Hogwarts.", subjects: ["Fantasy fiction"]},
    "/works/OL262758W" => {description: "The history of Middle-earth's First Age.", subjects: ["Fantasy fiction"]}
  }

  webmock.stub_request(:get, %r{openlibrary\.org/works/OL\d+W\.json}).to_return do |request|
    key = request.uri.path.delete_suffix(".json")
    {status: 200, headers: {"Content-Type" => "application/json"}, body: work_details.fetch(key, {}).to_json}
  end
end
