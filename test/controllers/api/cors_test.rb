require "test_helper"

class Api::CorsTest < ActionDispatch::IntegrationTest
  test "no CORS headers by default (API_CORS_ORIGINS unset in test env)" do
    process :options, api_v1_books_url, headers: {
      "HTTP_ORIGIN" => "https://example.com",
      "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET"
    }

    assert_nil response.headers["Access-Control-Allow-Origin"]
  end
end

# Built from the same ApiCorsConfig.apply as the real middleware, with an allow-listed origin.
class Api::CorsPolicyTest < ActiveSupport::TestCase
  test "an allow-listed origin may make credentialed requests" do
    app = Rack::Cors.new(->(_env) { [200, {}, ["ok"]] }) { ApiCorsConfig.apply(self, ["https://app.example.com"]) }
    env = Rack::MockRequest.env_for("/api/v1/session", "HTTP_ORIGIN" => "https://app.example.com")

    _status, headers, _body = app.call(env)

    assert_equal "https://app.example.com", headers["access-control-allow-origin"]
    assert_equal "true", headers["access-control-allow-credentials"]
  end

  test "an origin not on the list gets no CORS headers" do
    app = Rack::Cors.new(->(_env) { [200, {}, ["ok"]] }) { ApiCorsConfig.apply(self, ["https://app.example.com"]) }
    env = Rack::MockRequest.env_for("/api/v1/session", "HTTP_ORIGIN" => "https://evil.example.com")

    _status, headers, _body = app.call(env)

    assert_nil headers["access-control-allow-origin"]
  end
end

class ApiCorsConfigTest < ActiveSupport::TestCase
  test "blank env value allows no origins" do
    assert_equal [], ApiCorsConfig.allowed_origins(nil)
    assert_equal [], ApiCorsConfig.allowed_origins("")
  end

  test "parses a comma-separated list, trimming whitespace" do
    assert_equal ["https://example.com", "https://app.example.com"],
      ApiCorsConfig.allowed_origins(" https://example.com, https://app.example.com ")
  end

  test "localhost over http is allowed for development" do
    assert_equal ["http://localhost:3150"], ApiCorsConfig.allowed_origins("http://localhost:3150")
  end

  # Credentials are on, so plain-http, scheme-less and wildcard entries are refused at boot.
  test "rejects origins that aren't https" do
    ["http://app.example.com", "app.example.com", "*"].each do |raw|
      assert_raises(ArgumentError, raw) { ApiCorsConfig.allowed_origins(raw) }
    end
  end
end
