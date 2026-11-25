class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  before_action :require_admin

  def index
    @users = User.excluding_deleted_placeholder.order(:email).includes(:roles)
  end

  # Takes role names, not ids: ids differ between backends serving this contract.
  def update
    @user = User.excluding_deleted_placeholder.find(params.expect(:id))
    names = params.expect(user: {roles: []})[:roles].uniq
    roles = Role.where(name: names)
    unknown = names - roles.pluck(:name)

    if unknown.any?
      render json: {errors: ["Unknown roles: #{unknown.join(", ")}"]}, status: :unprocessable_content
    else
      update_roles_with_audit!(@user, roles)
      render :show
    end
  end
end
