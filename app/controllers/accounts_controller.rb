class AccountsController < ApplicationController
  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user

    if @user.update(account_params)
      # Only if this same request didn't also just attach a new one — e.g. a
      # user leaves "Remove avatar" checked from a prior page state and picks
      # a new file instead of unchecking it. The new upload wins.
      remove_avatar if params[:remove_avatar] == "1" && params.dig(:user, :avatar).blank?
      redirect_to edit_account_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @user = current_user
    authorize @user

    if !current_user.authenticated?(params[:current_password])
      flash.now[:alert] = "Current password was incorrect."
      render :edit, status: :unprocessable_content
    elsif current_user.sole_admin?
      flash.now[:alert] = "You're the only admin — promote another member to admin before deleting this account."
      render :edit, status: :unprocessable_content
    else
      user = current_user
      # sign_out must run before delete_account! destroys the record — it
      # writes a fresh remember_token to invalidate the session, which would
      # raise FrozenError against an already-destroyed (frozen) record.
      sign_out
      user.delete_account!
      # sign_in_path, not root_path: the user is now signed out, and root_path
      # requires login — it would immediately redirect again to sign_in_path,
      # whose own "please sign in" alert would clobber this notice before it's
      # ever rendered.
      redirect_to sign_in_path, notice: "Your account has been deleted."
    end
  end

  private

  def remove_avatar
    current_user.avatar.purge
  end

  def account_params
    params.expect(user: [:name, :bio, :avatar])
  end
end
