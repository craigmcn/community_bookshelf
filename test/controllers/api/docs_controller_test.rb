require "test_helper"

class Api::DocsControllerTest < ActionDispatch::IntegrationTest
  test "docs page is public and renders the Swagger UI mount point" do
    get api_docs_url
    assert_response :success
    assert_select "div#swagger-ui"
  end

  test "openapi spec is served as valid YAML" do
    get api_openapi_url

    assert_response :success
    assert_equal "application/yaml", @response.media_type

    spec = YAML.safe_load(@response.body)
    assert_equal "3.0.3", spec["openapi"]
    assert_includes spec["paths"].keys, "/readings/bulk"
  end

  test "the main site layout does not pull in the docs stylesheet" do
    get books_url
    assert_response :success
    assert_not_includes @response.body, "api_docs"
  end
end
