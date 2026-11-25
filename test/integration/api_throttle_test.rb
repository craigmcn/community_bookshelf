require "test_helper"

# Rails.cache is a :null_store in test, so this swaps in a MemoryStore for the throttle to count.
class ApiThrottleTest < ActionDispatch::IntegrationTest
  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rack::Attack.cache.store = @original_store
  end

  test "signed-out catalog reads share the 30/min per-IP limit" do
    30.times do
      get api_v1_books_url
      assert_response :success
    end

    get api_v1_book_url(books(:one))

    assert_response :too_many_requests
    assert_equal({"error" => "Rate limit exceeded"}, JSON.parse(response.body))
  end

  test "a signed-in reader isn't held to the per-IP limit" do
    headers = auth_headers(users(:member))
    31.times { get api_v1_books_url, headers: headers }

    assert_response :success
  end
end
