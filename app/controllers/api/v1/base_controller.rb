# standard:disable Rails/ApplicationController -- deliberately skips ApplicationController's
# Clearance session auth and HTML-flash Pundit rescue, neither of which apply to a token API.
class Api::V1::BaseController < ActionController::Base
  # standard:enable Rails/ApplicationController
  include Pundit::Authorization
  include Pagy::Backend

  skip_forgery_protection
  before_action { request.format = :json }
  before_action :authenticate_via_token!

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def authenticate_via_token!
    token = request.authorization&.split(" ")&.last
    @current_api_user = User.find_by(api_token: token) if token.present?
    render json: {error: "Invalid or missing API token"}, status: :unauthorized unless @current_api_user
  end

  def current_user
    @current_api_user
  end

  def render_forbidden
    render json: {error: "You are not authorized to perform this action."}, status: :forbidden
  end

  def render_not_found
    render json: {error: "Not found"}, status: :not_found
  end
end
