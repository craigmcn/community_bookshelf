require "test_helper"

class Api::RateLimitHeadersTest < ActionDispatch::IntegrationTest
  test "a successful authenticated request carries X-RateLimit headers" do
    get api_v1_books_url, headers: auth_headers(users(:member))

    assert_response :success
    assert_equal "120", response.headers["X-RateLimit-Limit"]
    assert response.headers["X-RateLimit-Remaining"].to_i <= 120
    assert response.headers["X-RateLimit-Reset"].present?
  end

  test "an unauthenticated request carries the IP-bucket X-RateLimit headers" do
    get api_v1_books_url, headers: {"Authorization" => "Bearer garbage"}

    assert_response :unauthorized
    assert_equal "30", response.headers["X-RateLimit-Limit"]
  end

  # Rack::Attack.cache defaults to Rails.cache, which is :null_store in the
  # test environment (see config/environments/test.rb) — counts never
  # persist there, so the throttle can never actually fire against it.
  # Swapping in a real MemoryStore just for this test lets us seed a
  # past-the-limit count and exercise the throttled_responder lambda for
  # real, rather than trusting its rack.attack.match_data handling untested.
  test "a throttled request gets a 429 with X-RateLimit headers" do
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    member = users(:member)
    token = api_token_for(member)
    headers = {"Authorization" => "Bearer #{token.plaintext_token}"}
    # Rack::Attack's default throttle_discriminator_normalizer downcases
    # every discriminator before it's used in the cache key, so the seeded
    # bucket has to match that normalized (lowercased) form too.
    discriminator = Rack::Attack.throttle_discriminator_normalizer.call(token.token_prefix)
    120.times { Rack::Attack.cache.count("api/token:#{discriminator}", 60) }

    get api_v1_books_url, headers: headers

    assert_response :too_many_requests
    assert_equal "120", response.headers["X-RateLimit-Limit"]
    assert_equal "0", response.headers["X-RateLimit-Remaining"]
    assert response.headers["X-RateLimit-Reset"].present?
  ensure
    Rack::Attack.cache.store = original_store
  end
end
