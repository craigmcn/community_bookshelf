# Be sure to restart your server when you modify this file.

# Only /api/v1/* is opened up — the rest of the app is server-rendered HTML
# and has no business responding to cross-origin fetches. API requests carry
# either a bearer token or, for the SPA, the session cookie (#219), so only an
# explicit env-driven origin allowlist is used, never "*" — API_CORS_ORIGINS is a
# comma-separated list, e.g. "https://example.com,https://app.example.com".
# Empty/unset means no cross-origin browser access until it's configured.
module ApiCorsConfig
  def self.allowed_origins(raw = ENV["API_CORS_ORIGINS"])
    raw.to_s.split(",").map(&:strip).compact_blank
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ApiCorsConfig.allowed_origins

    resource "/api/v1/*",
      headers: :any,
      methods: [:get, :post, :patch, :put, :delete, :options],
      # The SPA's cookie sign-in needs credentialed requests (#219). Only the explicit
      # allow-list above qualifies; rack-cors refuses credentials with a wildcard origin.
      credentials: true
  end
end
