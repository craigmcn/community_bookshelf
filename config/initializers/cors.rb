# Be sure to restart your server when you modify this file.

# Only /api/v1/* is opened up — the rest of the app is server-rendered HTML
# and has no business responding to cross-origin fetches. API requests carry
# either a bearer token or, for the SPA, the session cookie (#219), so only an
# explicit env-driven origin allowlist is used, never "*" — API_CORS_ORIGINS is a
# comma-separated list, e.g. "https://example.com,https://app.example.com".
# Empty/unset means no cross-origin browser access until it's configured.
# Credentials are on, so every listed origin can make signed-in requests and read
# a user's CSRF token: list only origins trusted with users' sessions.
module ApiCorsConfig
  # Plain http would let a network attacker inject script into a credentialed origin.
  # localhost is allowed for development (e.g. the SPA on :3150).
  ORIGIN_FORMAT = %r{\A(https://[^\s/]+|http://(localhost|127\.0\.0\.1)(:\d+)?)\z}

  def self.allowed_origins(raw = ENV["API_CORS_ORIGINS"])
    origins = raw.to_s.split(",").map(&:strip).compact_blank
    invalid = origins.grep_v(ORIGIN_FORMAT)
    raise ArgumentError, "API_CORS_ORIGINS entries must be https:// origins (or http://localhost): #{invalid.join(", ")}" if invalid.any?

    origins
  end

  # Shared with the CORS test, so it exercises the real policy rather than a copy.
  def self.apply(cors, origins)
    cors.allow do
      origins(*origins)

      resource "/api/v1/*",
        headers: :any,
        methods: [:get, :post, :patch, :put, :delete, :options],
        # The SPA's cookie sign-in needs credentialed requests (#219). A "*" entry fails
        # allowed_origins at boot, as rack-cors itself refuses credentials with a wildcard.
        credentials: true
    end
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  ApiCorsConfig.apply(self, ApiCorsConfig.allowed_origins)
end
