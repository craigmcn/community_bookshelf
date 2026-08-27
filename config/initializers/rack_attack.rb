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

  self.throttled_responder = lambda do |_request|
    [429, {"Content-Type" => "application/json"}, [{error: "Rate limit exceeded"}.to_json]]
  end
end
