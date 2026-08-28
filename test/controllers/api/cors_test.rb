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

class ApiCorsConfigTest < ActiveSupport::TestCase
  test "blank env value allows no origins" do
    assert_equal [], ApiCorsConfig.allowed_origins(nil)
    assert_equal [], ApiCorsConfig.allowed_origins("")
  end

  test "parses a comma-separated list, trimming whitespace" do
    assert_equal ["https://example.com", "https://app.example.com"],
      ApiCorsConfig.allowed_origins(" https://example.com, https://app.example.com ")
  end
end
