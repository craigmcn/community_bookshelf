class Admin::UsersController < Admin::BaseController
  def index
    @users = User.all.order(:email)
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(role: params[:user][:role])
      redirect_to admin_users_path, notice: "Role updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
