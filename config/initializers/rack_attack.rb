class Rack::Attack
  # Bucketing on the raw Authorization header would let an attacker dodge
  # both throttles below by sending a fresh garbage token on every request
  # (each string gets its own "api/token" bucket, and it's never blank, so
  # "api/ip-unauthenticated" never engages either). Resolving against a real
  # user closes that gap: a valid token or cookie throttles by client, anything
  # else — missing or garbage — throttles by IP instead.
  def self.verified_api_token(req)
    token = authorization(req)&.split(" ")&.last
    return nil if token.blank?

    prefix = token[0, ApiToken::DISPLAY_PREFIX_LENGTH]
    prefix if ApiToken.active.exists?(token_prefix: prefix)
  end

  # Same source as Api::V1::BaseController#token_auth?, so both agree on which auth applies.
  def self.authorization(req)
    ActionDispatch::Request.new(req.env).authorization
  end

  # Mirrors the API's precedence (#219): a header means token auth only, so a valid cookie
  # beside a garbage token still counts as unauthenticated. Cookie sessions bucket per user.
  def self.verified_api_client(req)
    return req.env["bookshelf.api_client"] if req.env.key?("bookshelf.api_client")

    req.env["bookshelf.api_client"] =
      if authorization(req).present?
        verified_api_token(req)
      # Raw read assumes Clearance's signed_cookie is off; signing it would need the cookie jar here.
      elsif (remember_token = req.cookies[Clearance.configuration.cookie_name]).present?
        user_id = User.where(remember_token: remember_token).pick(:id)
        "user:#{user_id}" if user_id
      end
  end

  throttle("api/token", limit: 120, period: 1.minute) do |req|
    verified_api_client(req) if req.path.start_with?("/api/")
  end

  throttle("api/ip-unauthenticated", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/") && verified_api_client(req).nil?
  end

  # Each path maps to the field its controller reads the email from (nil = top level), so
  # the per-email throttle counts exactly the address being signed in or reset.
  SIGN_IN_EMAIL_SCOPES = {"/session" => "session", "/api/v1/session" => nil}.freeze
  PASSWORD_RESET_PATH = "/passwords"

  # The routes accept a format suffix, so "/session.html" must count as "/session".
  def self.route_path(req)
    req.path.sub(%r{\.[^/.]+\z}, "").chomp("/")
  end

  def self.sign_in_attempt?(req)
    req.post? && SIGN_IN_EMAIL_SCOPES.key?(route_path(req))
  end

  def self.password_reset_request?(req)
    req.post? && route_path(req) == PASSWORD_RESET_PATH
  end

  # The same merged params the controllers read (a query-string email overrides the body), so a
  # decoy can't be counted in place of the real address. Clearance's normalizer joins "m ember@x".
  def self.submitted_email(req, scope)
    params = ActionDispatch::Request.new(req.env).parameters
    params = params[scope] if scope
    email = params["email"] if params.is_a?(Hash)
    User.normalize_email(email).presence if email.is_a?(String)
  rescue ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError
    nil
  end

  # Per IP stops one client guessing across many accounts; per email stops a botnet
  # spreading guesses at one account across many IPs.
  throttle("sign-in/ip", limit: 10, period: 1.minute) do |req|
    req.ip if sign_in_attempt?(req)
  end

  throttle("sign-in/email", limit: 5, period: 1.minute) do |req|
    submitted_email(req, SIGN_IN_EMAIL_SCOPES[route_path(req)]) if sign_in_attempt?(req)
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
    # Rack 3 requires lowercase response header names.
    headers = (match_data ? rate_limit_headers(match_data) : {}).transform_keys(&:downcase)

    if request.path.start_with?("/api/")
      [429, headers.merge("content-type" => "application/json"), [{error: "Rate limit exceeded"}.to_json]]
    else
      [429, headers.merge("content-type" => "text/html; charset=utf-8"), [Rails.public_path.join("429.html").read]]
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
