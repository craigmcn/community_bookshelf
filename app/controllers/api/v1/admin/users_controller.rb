class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  before_action :require_admin
  before_action :require_json_body, only: :update

  def index
    @users = User.excluding_deleted_placeholder.order(:email).includes(:roles)
  end

  # Takes role names, not ids: ids differ between backends serving this contract.
  def update
    @user = User.excluding_deleted_placeholder.find(params.expect(:id))
    names = submitted_role_names
    return render json: {error: "user.roles must be a list of role names"}, status: :bad_request unless names

    roles = Role.where(name: names)
    unknown = names - roles.pluck(:name)

    if unknown.any?
      render json: {errors: ["Unknown roles: #{unknown.join(", ")}"]}, status: :unprocessable_content
    else
      update_roles_with_audit!(@user, roles)
      render :show
    end
  end

  private

  # Read from the raw body: Rails drops nulls from arrays, so [null] would arrive as [] and
  # strip every role. Anything but a list of strings changes nothing.
  def submitted_role_names
    body = JSON.parse(request.raw_post)
    roles = body.dig("user", "roles") if body.is_a?(Hash) && body["user"].is_a?(Hash)
    roles.uniq if roles.is_a?(Array) && roles.all?(String)
  rescue JSON::ParserError
    nil
  end
end
