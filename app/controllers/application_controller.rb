class ApplicationController < ActionController::Base
  include Clearance::Controller
  include Pundit::Authorization
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_login

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back_or_to(root_path)
  end

  # Only called at moderator/admin-gated mutation points (role changes,
  # book/reading destroys) — not every write in the app, just the ones an
  # admin performs on someone else's behalf.
  def log_audit_action!(action:, subject:, details: {})
    AuditLog.create!(actor: current_user, action: action, subject: subject, details: details)
  end

  # Audited only when someone deletes another member's reading; removing your own is routine.
  def soft_delete_reading!(reading)
    ActiveRecord::Base.transaction do
      reading.soft_delete
      next if reading.user == current_user

      log_audit_action!(
        action: "destroy_reading",
        subject: reading,
        details: {owner_email: reading.user.email, book_title: reading.book.title}
      )
    end
  end
end
