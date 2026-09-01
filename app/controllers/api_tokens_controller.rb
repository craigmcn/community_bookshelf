class ApiTokensController < ApplicationController
  EXPIRY_OPTIONS = {
    "30" => 30.days,
    "90" => 90.days,
    "365" => 365.days,
    "never" => nil
  }.freeze

  def index
    authorize ApiToken
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
  end

  def new
    @api_token = current_user.api_tokens.build
  end

  def create
    # Unchecking every scope checkbox omits api_token[scopes] from the
    # request entirely (check_box_tag has no hidden fallback field), so
    # scopes must default to [] here rather than staying nil — otherwise the
    # re-rendered form's @api_token.scopes.include?(scope) raises instead of
    # showing the "can't be blank" validation error.
    @api_token = current_user.api_tokens.build(scopes: params.dig(:api_token, :scopes)&.reject(&:blank?) || [])
    authorize @api_token

    expires_at = expires_at_from_param(params.dig(:api_token, :expires_in))
    generated = ApiToken.generate!(user: current_user, name: token_params[:name], scopes: @api_token.scopes, expires_at: expires_at)

    redirect_to api_tokens_path, notice: "API token created.", flash: {new_token: generated.plaintext_token}
  rescue ActiveRecord::RecordInvalid => e
    @api_token = e.record
    render :new, status: :unprocessable_content
  end

  # Scoped to current_user.api_tokens rather than a bare find, so a non-owner
  # requesting another user's token id gets a 404 instead of ever reaching
  # the authorize call.
  def destroy
    @api_token = current_user.api_tokens.find(params.expect(:id))
    authorize @api_token
    @api_token.destroy!
    redirect_to api_tokens_path, notice: "API token revoked.", status: :see_other
  end

  private

  def token_params
    params.expect(api_token: [:name])
  end

  def expires_at_from_param(value)
    return nil unless EXPIRY_OPTIONS.key?(value)

    EXPIRY_OPTIONS.fetch(value)&.from_now
  end
end
