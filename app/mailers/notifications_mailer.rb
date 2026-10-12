class NotificationsMailer < ApplicationMailer
  helper NotificationsHelper

  def digest(user, notification_ids)
    @user = user
    @notifications = Notification.where(id: notification_ids).with_message_associations.recent.to_a
    return if @notifications.empty?

    mail(to: @user.email, subject: "Your Community Bookshelf digest")
  end
end
