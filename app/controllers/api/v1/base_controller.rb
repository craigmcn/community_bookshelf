# standard:disable Rails/ApplicationController -- deliberately skips ApplicationController's
# Clearance session auth and HTML-flash Pundit rescue, neither of which apply to a token API.
class Api::V1::BaseController < ActionController::Base
  # standard:enable Rails/ApplicationController
  include Pundit::Authorization
  include Pagy::Method

  skip_forgery_protection
  before_action { request.format = :json }
  # Runs before authenticate_via_token! (and unlike an after_action, still
  # runs even when that before_action halts the chain with a 401 render) so
  # every response — successful or not — carries the headers.
  before_action :set_rate_limit_headers
  before_action :authenticate_via_token!

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  # Rack::Attack annotates request.env with throttle_data for every request
  # that matched a throttle's discriminator, not just ones that got blocked
  # (see Rack::Attack::Throttle#matched_by?) — so a well-behaved client can
  # see how close it is to the limit before ever hitting a 429.
  def set_rate_limit_headers
    throttle_data = request.env["rack.attack.throttle_data"]&.values&.first
    return unless throttle_data

    response.headers.merge!(Rack::Attack.rate_limit_headers(throttle_data))
  end

  def authenticate_via_token!
    token = request.authorization&.split(" ")&.last
    @current_api_token = ApiToken.authenticate(token) if token.present?
    @current_api_token&.touch_last_used!
    render json: {error: "Invalid or missing API token"}, status: :unauthorized unless @current_api_token
  end

  def current_user
    @current_api_token&.user
  end

  def require_scope!(scope)
    return if @current_api_token.scopes.include?(scope.to_s)

    render json: {error: "Token missing required scope: #{scope}"}, status: :forbidden
  end

  def render_forbidden
    render json: {error: "You are not authorized to perform this action."}, status: :forbidden
  end

  def render_not_found
    render json: {error: "Not found"}, status: :not_found
  end
end
