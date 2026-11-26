# Cookie sign-in for the SPA (#219). These endpoints are cookie-only, so a leaked API token
# can't be used to open or inspect a browser session.
class Api::V1::SessionsController < Api::V1::BaseController
  include Clearance::Authentication

  skip_before_action :authenticate!
  before_action :reject_token_auth
  # A cross-site HTML form could otherwise sign the victim's browser in as the attacker (login CSRF).
  before_action :require_json_body, only: :create
  before_action :authenticate_via_cookie!, only: [:show, :destroy]

  def show
    render_session(status: :ok)
  end

  # Reads a top-level email, which rack_attack.rb's sign-in/email throttle counts.
  def create
    user = User.authenticate(params[:email].to_s, params[:password].to_s)
    # Clearance rotates the CSRF token after this block runs, so render only once it returns:
    # a token generated inside the block would already be stale.
    status = nil
    sign_in(user) { |result| status = result }

    if status.success?
      @cookie_user = current_user
      render_session(status: :created)
    else
      render json: {error: status.failure_message}, status: :unauthorized
    end
  end

  def destroy
    sign_out
    head :no_content
  end

  private

  def render_session(status:)
    @user = @cookie_user
    @csrf_token = form_authenticity_token
    render :show, status: status
  end
end
