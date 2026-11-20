require "test_helper"

# Postgres rejects strings containing NUL, and the PG adapter raises ArgumentError when one
# is bound into a query, so these requests used to 500 (#246). NullByteGuard turns them into 400s.
class NullByteGuardTest < ActionDispatch::IntegrationTest
  test "a NUL in a search or tag query param is a 400" do
    ["/books?q=a%00b", "/books?tag=a%00b"].each do |path|
      get path
      assert_response :bad_request, path
    end
  end

  test "a NUL in a signed-in shelf search is a 400" do
    sign_in_as users(:member)
    get "/readings?q=a%00b"
    assert_response :bad_request
  end

  test "a NUL in a path segment is a 400" do
    get "/confirm_email/a%00b"
    assert_response :bad_request
  end

  test "a NUL in a form field (sign-in email) is a 400" do
    post session_url, params: {session: {email: "a\0b@example.com", password: "x"}}
    assert_response :bad_request
  end

  test "a NUL in a param key is a 400" do
    get "/books?a%00b=1"
    assert_response :bad_request
  end

  test "a NUL in a cookie is a 400" do
    get books_url, headers: {"Cookie" => "remember_token=a%00b"}
    assert_response :bad_request
  end

  test "an API request with a NUL is a 400 in the API's error shape" do
    get "/api/v1/books?q=a%00b", headers: auth_headers(users(:member))

    assert_response :bad_request
    assert_equal({"error" => "Request contains a null byte"}, JSON.parse(response.body))
  end

  test "a NUL in the API bearer token is a 400, before Rack::Attack looks it up" do
    get "/api/v1/books", headers: {"Authorization" => "Bearer cb_ab\0cd1234"}
    assert_response :bad_request
  end

  test "a NUL in a JSON body string is a 400" do
    post "/api/v1/readings",
      params: {reading: {book_id: books(:two).id, status: "reading", review: "a\u0000b"}}.to_json,
      headers: auth_headers(users(:member)).merge("Content-Type" => "application/json")
    assert_response :bad_request
  end

  test "an uploaded file containing NUL bytes is still accepted" do
    assert_includes file_fixture("avatar.png").binread, "\0" # guards the premise
    sign_in_as users(:member)

    patch account_url, params: {user: {avatar: fixture_file_upload("avatar.png", "image/png")}}

    assert_redirected_to edit_account_url
    assert users(:member).reload.avatar.attached?
  end

  test "ordinary requests pass through untouched" do
    get "/books?q=gatsby"
    assert_response :success
  end
end

# Called directly: the guard sits upstream of Rack::TempfileReaper, so a rejected multipart
# request must close its own upload tempfiles or they stay open until GC.
class NullByteGuardTempfileTest < ActiveSupport::TestCase
  test "a rejected multipart request closes its upload tempfiles" do
    upload = Rack::Multipart::UploadedFile.new(file_fixture("avatar.png").to_s, "image/png")
    env = Rack::MockRequest.env_for("/account", method: "PATCH", params: {"user" => {"name" => "a\0b", "avatar" => upload}})

    status, = NullByteGuard.new(->(_env) { [200, {}, []] }).call(env)

    assert_equal 400, status
    assert_not_empty env[Rack::RACK_TEMPFILES]
    assert env[Rack::RACK_TEMPFILES].all?(&:closed?)
  end
end
