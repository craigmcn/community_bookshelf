class Rack::Attack
  # Bucketing on the raw Authorization header would let an attacker dodge
  # both throttles below by sending a fresh garbage token on every request
  # (each string gets its own "api/token" bucket, and it's never blank, so
  # "api/ip-unauthenticated" never engages either). Resolving against a real
  # user closes that gap: a valid token throttles by token, anything else —
  # missing or garbage — throttles by IP instead.
  def self.verified_api_token(req)
    token = req.get_header("HTTP_AUTHORIZATION")&.split(" ")&.last
    token if token.present? && User.exists?(api_token: token)
  end

  throttle("api/token", limit: 120, period: 1.minute) do |req|
    verified_api_token(req) if req.path.start_with?("/api/")
  end

  throttle("api/ip-unauthenticated", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/") && verified_api_token(req).nil?
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    headers = {"Content-Type" => "application/json"}
    headers.merge!(rate_limit_headers(match_data)) if match_data
    [429, headers, [{error: "Rate limit exceeded"}.to_json]]
  end

  # X-RateLimit-* headers on a throttled (429) response — the non-throttled
  # case is handled separately by Api::V1::BaseController, which has access
  # to request.env["rack.attack.throttle_data"] (populated for every
  # matching request, not just throttled ones) via a before_action.
  def self.rate_limit_headers(data)
    {
      "X-RateLimit-Limit" => data[:limit].to_s,
      "X-RateLimit-Remaining" => [data[:limit] - data[:count], 0].max.to_s,
      "X-RateLimit-Reset" => (data[:epoch_time] + data[:period]).to_i.to_s
    }
  end
end
