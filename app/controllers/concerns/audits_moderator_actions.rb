# Shared by ApplicationController and Api::V1::BaseController so a moderator delete is
# audited the same way through the website and /api/v1. Both trees define current_user
# (session user vs. token user), which is the audit actor.
module AuditsModeratorActions
  extend ActiveSupport::Concern

  private

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
      unless reading.user == current_user
        log_audit_action!(
          action: "destroy_reading",
          subject: reading,
          details: {owner_email: reading.user.email, book_title: reading.book.title}
        )
      end
    end
  end

  def destroy_book_with_audit!(book)
    title = book.title
    ActiveRecord::Base.transaction do
      book.destroy!
      log_audit_action!(action: "destroy_book", subject: book, details: {title: title})
    end
  end
end
