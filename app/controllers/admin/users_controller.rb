class Admin::UsersController < Admin::BaseController
  before_action :require_admin

  def index
    @users = User.all.order(:email).includes(:roles)
  end

  def edit
    @user = User.find(params[:id])
    @roles = Role.all.order(:name)
  end

  def update
    @user = User.find(params[:id])
    @user.roles = Role.where(id: params.dig(:user, :role_ids) || [])
    redirect_to admin_users_path, notice: "Roles updated."
  end
end
