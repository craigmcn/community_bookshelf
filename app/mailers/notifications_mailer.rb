class NotificationsMailer < ApplicationMailer
  helper NotificationsHelper

  def digest(user)
    @user = user
    @notifications = user.notifications.not_yet_digested.includes(:actor, :notifiable).recent.to_a
    return if @notifications.empty?

    mail(to: @user.email, subject: "Your Community Bookshelf digest")
  end
end
