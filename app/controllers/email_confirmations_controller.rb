class EmailConfirmationsController < ApplicationController
  skip_before_action :require_login, only: [:confirm]

  def create
    current_user.send_email_confirmation
    redirect_to edit_account_path, notice: "Confirmation email sent."
  end

  def confirm
    user = User.find_by(email_confirmation_token: params[:token])
    # root_path requires login, so a signed-out visitor (confirming from a
    # device other than the one they're signed in on, or not signed in at
    # all) would just get redirected straight through to sign_in_path —
    # losing this flash message to whatever require_login sets there.
    destination = signed_in? ? root_path : sign_in_path

    if user&.confirm_email!(params[:token])
      redirect_to destination, notice: "Email confirmed."
    else
      redirect_to destination, alert: "That confirmation link is invalid or has expired."
    end
  end
end
