require "test_helper"
require "webmock/minitest"

class OpenLibraryServiceTest < ActiveSupport::TestCase
  test "search includes the open_library_key for each result" do
    stub_request(:get, /openlibrary\.org\/search\.json/)
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {docs: [{title: "The Great Gatsby", author_name: ["F. Scott Fitzgerald"], key: "/works/OL468431W"}]}.to_json
      )

    results = OpenLibraryService.search("gatsby")

    assert_equal "/works/OL468431W", results.first[:open_library_key]
  end

  test "work_detail returns description and subjects" do
    stub_request(:get, "https://openlibrary.org/works/OL468431W.json")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {description: "A novel about the American Dream.", subjects: ["Fiction", "Classics"]}.to_json
      )

    detail = OpenLibraryService.work_detail("/works/OL468431W")

    assert_equal "A novel about the American Dream.", detail[:description]
    assert_equal ["Fiction", "Classics"], detail[:subjects]
  end

  test "work_detail unwraps a description hash" do
    stub_request(:get, "https://openlibrary.org/works/OL468431W.json")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {description: {type: "/type/text", value: "A novel about the American Dream."}}.to_json
      )

    detail = OpenLibraryService.work_detail("/works/OL468431W")

    assert_equal "A novel about the American Dream.", detail[:description]
  end

  test "work_detail returns an empty hash when the key is blank" do
    assert_equal({}, OpenLibraryService.work_detail(nil))
    assert_equal({}, OpenLibraryService.work_detail(""))
  end

  test "work_detail rejects keys that don't match the Open Library work format" do
    assert_equal({}, OpenLibraryService.work_detail("http://evil.example.com/works/OL468431W"))
    assert_equal({}, OpenLibraryService.work_detail("/books/OL468431M"))
    assert_equal({}, OpenLibraryService.work_detail("/works/OL468431W/../../admin"))
  end

  test "work_detail returns an empty hash on a network error" do
    stub_request(:get, "https://openlibrary.org/works/OL468431W.json").to_timeout

    assert_equal({}, OpenLibraryService.work_detail("/works/OL468431W"))
  end

  # Faraday doesn't raise on an error status, so each of these reached JSON.parse or #filter_map.
  test "search returns no results when Open Library fails or answers oddly" do
    [
      {status: 503, body: "<html>Down</html>"},
      {status: 429, body: "slow down"},
      {status: 500, body: {docs: [{title: "From an error page"}]}.to_json},
      {status: 200, body: ""},
      {status: 200, body: {numFound: 0}.to_json},
      {status: 200, body: [1, 2].to_json},
      {status: 200, body: {docs: "nope"}.to_json},
      {status: 200, body: {docs: [nil, "x", {title: "Kept"}]}.to_json}
    ].each do |reply|
      WebMock.reset!
      stub_request(:get, /openlibrary\.org\/search\.json/).to_return(**reply, headers: {"Content-Type" => "application/json"})

      results = OpenLibraryService.search("gatsby")

      expected = reply[:body].include?("Kept") ? ["Kept"] : []
      assert_equal expected, results.pluck(:title), reply.inspect
    end
  end
end
