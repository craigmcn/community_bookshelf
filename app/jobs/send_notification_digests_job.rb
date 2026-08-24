class SendNotificationDigestsJob < ApplicationJob
  queue_as :default

  def perform
    User.excluding_deleted_placeholder.joins(:notifications).merge(Notification.not_yet_digested).distinct.find_each do |user|
      notification_ids = user.notifications.not_yet_digested.pluck(:id)
      NotificationsMailer.digest(user).deliver_later
      Notification.where(id: notification_ids).update_all(digested_at: Time.current)
    end
  end
end
