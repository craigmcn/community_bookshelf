class Admin::UsersController < Admin::BaseController
  before_action :require_admin

  def index
    @users = User.excluding_deleted_placeholder.order(:email).includes(:roles)
  end

  def edit
    @user = User.excluding_deleted_placeholder.find(params[:id])
    @roles = Role.all.order(:name)
  end

  def update
    @user = User.excluding_deleted_placeholder.find(params[:id])
    previous_roles = @user.roles.order(:name).pluck(:name)

    ActiveRecord::Base.transaction do
      @user.roles = Role.where(id: params.dig(:user, :role_ids) || [])
      log_audit_action!(
        action: "update_roles",
        subject: @user,
        details: {from: previous_roles, to: @user.roles.reload.order(:name).pluck(:name)}
      )
    end

    redirect_to admin_users_path, notice: "Roles updated."
  end
end
