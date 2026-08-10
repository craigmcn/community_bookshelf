if ENV["OPEN_LIBRARY_STUB"] == "1"
  require "webmock"
  WebMock.enable!
  WebMock.allow_net_connect!

  include WebMock::API

  stub_request(:get, /openlibrary\.org\/search\.json/).to_return do |request|
    query = Rack::Utils.parse_nested_query(request.uri.query)["q"].to_s.downcase

    docs = [
      {title: "The Hobbit", author_name: ["J.R.R. Tolkien"], cover_i: 1},
      {title: "The Great Gatsby", author_name: ["F. Scott Fitzgerald"], cover_i: 2},
      {title: "1984", author_name: ["George Orwell"], cover_i: 3}
    ].select { |doc| doc[:title].downcase.include?(query) }

    {status: 200, headers: {"Content-Type" => "application/json"}, body: {docs: docs}.to_json}
  end
end
