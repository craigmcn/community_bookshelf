class SendNotificationDigestsJob < ApplicationJob
  queue_as :default

  def perform
    User.excluding_deleted_placeholder.joins(:notifications).merge(Notification.not_yet_digested).distinct.find_each do |user|
      notification_ids = user.notifications.not_yet_digested.pluck(:id)
      # notification_ids is passed explicitly rather than left for the
      # mailer to re-derive via not_yet_digested: deliver_later only
      # enqueues the mailer name/method/args, so by the time the queued
      # ActionMailer::MailDeliveryJob actually calls #digest again, the
      # digested_at update below has already run — a scope re-query at that
      # point would come back empty and silently drop the email.
      NotificationsMailer.digest(user, notification_ids).deliver_later
      Notification.where(id: notification_ids).update_all(digested_at: Time.current)
    end
  end
end
