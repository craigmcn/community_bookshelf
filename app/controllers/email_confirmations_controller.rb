class EmailConfirmationsController < ApplicationController
  skip_before_action :require_login, only: [:confirm]

  def create
    current_user.send_email_confirmation
    redirect_to edit_account_path, notice: "Confirmation email sent."
  end

  def confirm
    user = User.find_by(email_confirmation_token: params[:token])

    if user&.confirm_email!(params[:token])
      redirect_to root_path, notice: "Email confirmed."
    else
      redirect_to root_path, alert: "That confirmation link is invalid or has expired."
    end
  end
end
