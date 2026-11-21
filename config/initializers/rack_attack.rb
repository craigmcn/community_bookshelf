class Rack::Attack
  # Bucketing on the raw Authorization header would let an attacker dodge
  # both throttles below by sending a fresh garbage token on every request
  # (each string gets its own "api/token" bucket, and it's never blank, so
  # "api/ip-unauthenticated" never engages either). Resolving against a real
  # user closes that gap: a valid token throttles by token, anything else —
  # missing or garbage — throttles by IP instead.
  def self.verified_api_token(req)
    token = req.get_header("HTTP_AUTHORIZATION")&.split(" ")&.last
    return nil if token.blank?

    prefix = token[0, ApiToken::DISPLAY_PREFIX_LENGTH]
    prefix if ApiToken.active.exists?(token_prefix: prefix)
  end

  throttle("api/token", limit: 120, period: 1.minute) do |req|
    verified_api_token(req) if req.path.start_with?("/api/")
  end

  throttle("api/ip-unauthenticated", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/") && verified_api_token(req).nil?
  end

  SIGN_IN_PATHS = ["/session", "/api/v1/session"].freeze

  def self.sign_in_attempt?(req)
    req.post? && SIGN_IN_PATHS.include?(req.path)
  end

  def self.password_reset_request?(req)
    req.post? && req.path == "/passwords"
  end

  # Rails' parser handles JSON bodies too (/api/v1/session), and NullByteGuard has already
  # cached the parse in the env. A malformed body has no email, and Rails rejects it downstream.
  def self.submitted_email(req, scope)
    params = ActionDispatch::Request.new(req.env).request_parameters
    email = params.dig(scope, "email") || params["email"]
    email.downcase.strip.presence if email.is_a?(String)
  rescue ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError
    nil
  end

  # Per IP stops one client guessing across many accounts; per email stops a botnet
  # spreading guesses at one account across many IPs.
  throttle("sign-in/ip", limit: 10, period: 1.minute) do |req|
    req.ip if sign_in_attempt?(req)
  end

  throttle("sign-in/email", limit: 5, period: 1.minute) do |req|
    submitted_email(req, "session") if sign_in_attempt?(req)
  end

  # Each reset request sends mail, so these also stop one inbox being flooded.
  throttle("password-reset/ip", limit: 5, period: 1.minute) do |req|
    req.ip if password_reset_request?(req)
  end

  throttle("password-reset/email", limit: 3, period: 15.minutes) do |req|
    submitted_email(req, "password") if password_reset_request?(req)
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    headers = match_data ? rate_limit_headers(match_data) : {}

    if request.path.start_with?("/api/")
      [429, headers.merge("Content-Type" => "application/json"), [{error: "Rate limit exceeded"}.to_json]]
    else
      [429, headers.merge("Content-Type" => "text/html; charset=utf-8"), [Rails.public_path.join("429.html").read]]
    end
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
