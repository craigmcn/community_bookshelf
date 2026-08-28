require "test_helper"
require "webmock/minitest"

class BookSearchControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get book_search_url(q: "gatsby")
    assert_redirected_to sign_in_path
  end

  test "results frame is a live region so screen readers announce updates" do
    stub_request(:get, "https://openlibrary.org/search.json")
      .with(query: hash_including({"q" => "gatsby"}))
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {docs: [{title: "The Great Gatsby", author_name: ["F. Scott Fitzgerald"], key: "/works/OL468431W"}]}.to_json
      )

    sign_in_as users(:member)
    get book_search_url(q: "gatsby")

    assert_response :success
    assert_select "turbo-frame#book-search-results[aria-live=polite][aria-atomic=true]"
    assert_includes @response.body, "1 result found."
  end

  test "empty query renders the frame with no results markup" do
    sign_in_as users(:member)
    get book_search_url(q: "")

    assert_response :success
    assert_select "turbo-frame#book-search-results[aria-live=polite]"
    assert_not_includes @response.body, "No results found."
  end

  test "no matches shows the no-results message inside the live region" do
    stub_request(:get, "https://openlibrary.org/search.json")
      .with(query: hash_including({"q" => "zzzznomatch"}))
      .to_return(status: 200, headers: {"Content-Type" => "application/json"}, body: {docs: []}.to_json)

    sign_in_as users(:member)
    get book_search_url(q: "zzzznomatch")

    assert_response :success
    assert_includes @response.body, "No results found."
  end
end
