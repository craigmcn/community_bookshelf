# standard:disable Rails/ApplicationController -- deliberately skips ApplicationController's
# HTML-flash Pundit rescue and redirecting require_login; auth here is a bearer token or the
# Clearance cookie, each answering with JSON (#219).
class Api::V1::BaseController < ActionController::Base
  # standard:enable Rails/ApplicationController
  include Pundit::Authorization
  include Pagy::Method
  include AuditsModeratorActions
  include SearchQuery

  ANONYMOUS_SCOPES = %w[read:books].freeze

  # Rails' form-param CSRF check doesn't fit token clients; cookie writes are checked by
  # verify_csrf_token! instead, against the X-CSRF-Token header.
  skip_forgery_protection
  # Needed so far only by the club_posts spoiler-visibility check in jbuilder
  # views (app/views/api/v1/clubs/show.json.jbuilder) — current_user is
  # otherwise only ever used from controller code, which can already call
  # private methods directly.
  helper_method :current_user
  before_action { request.format = :json }
  # Runs before authenticate! (and unlike an after_action, still
  # runs even when that before_action halts the chain with a 401 render) so
  # every response — successful or not — carries the headers.
  before_action :set_rate_limit_headers
  before_action :authenticate!

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  # Rack::Attack records throttle_data for every matching request, not just blocked ones, so
  # clients see how close they are. Several throttles can match (sign-in adds its own), so
  # report the one nearest its limit: it's the one that will 429 first.
  def set_rate_limit_headers
    throttle_data = request.env["rack.attack.throttle_data"]&.values&.min_by { |data| data[:limit] - data[:count] }
    return unless throttle_data

    response.headers.merge!(Rack::Attack.rate_limit_headers(throttle_data))
  end

  # An Authorization header means token auth only: a bad token is a 401, never a fallback to
  # the cookie. Without one, the Clearance cookie session is used, with CSRF checked on writes.
  def authenticate!
    if token_auth?
      authenticate_via_token!
    else
      authenticate_via_cookie!
    end
  end

  # For reads that are public on the website: signed-out visitors get through, but a bad
  # token is still a 401, so a script with an expired one isn't silently downgraded.
  def authenticate_if_present!
    token_auth? ? authenticate_via_token! : @cookie_user = clearance_session.current_user
  end

  def reject_token_auth
    render json: {error: "This endpoint takes a session cookie, not an API token"}, status: :forbidden if token_auth?
  end

  # HTML forms can't send JSON, and cross-site fetch can't send it without a CORS preflight.
  def require_json_body
    return if request.media_type == "application/json"

    render json: {error: "Content-Type must be application/json"}, status: :unsupported_media_type
  end

  def token_auth?
    request.authorization.present?
  end

  def authenticate_via_token!
    token = request.authorization.split(" ").last
    @current_api_token = ApiToken.authenticate(token) if token.present?
    @current_api_token&.touch_last_used!
    render json: {error: "Invalid or missing API token"}, status: :unauthorized unless @current_api_token
  end

  def authenticate_via_cookie!
    @cookie_user = clearance_session.current_user
    return render json: {error: "Not signed in: send an API token or a session cookie"}, status: :unauthorized unless @cookie_user

    verify_csrf_token!
  end

  def verify_csrf_token!
    return if request.get? || request.head?
    return if valid_authenticity_token?(session, request.headers["X-CSRF-Token"])

    render json: {error: "Invalid CSRF token"}, status: :forbidden
  end

  def clearance_session
    request.env[:clearance]
  end

  def current_user
    @current_api_token&.user || @cookie_user
  end

  # A cookie session can do everything the website can, so it holds every scope. Signed-out
  # visitors only reach the actions that use authenticate_if_present!, and may only read books.
  def current_scopes
    return @current_api_token.scopes if @current_api_token

    @cookie_user ? ApiToken::SCOPES : ANONYMOUS_SCOPES
  end

  def require_scope!(scope)
    return if current_scopes.include?(scope.to_s)

    render json: {error: "Token missing required scope: #{scope}"}, status: :forbidden
  end

  def render_forbidden
    render json: {error: "You are not authorized to perform this action."}, status: :forbidden
  end

  def render_not_found
    render json: {error: "Not found"}, status: :not_found
  end
end
