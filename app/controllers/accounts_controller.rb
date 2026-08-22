class AccountsController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(account_params)
      remove_avatar if params[:remove_avatar] == "1"
      redirect_to edit_account_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if current_user.authenticated?(params[:current_password])
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
    else
      @user = current_user
      flash.now[:alert] = "Current password was incorrect."
      render :edit, status: :unprocessable_content
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
