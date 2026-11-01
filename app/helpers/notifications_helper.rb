module NotificationsHelper
  def notification_path_for(notification)
    case notification.notification_type
    when "new_follower" then user_path(notification.actor)
    when "review_comment" then reading_path(notification.notifiable.reading)
    when "club_post" then club_path(notification.notifiable.club)
    when "buddy_read_invite" then buddy_read_path(notification.notifiable)
    when "buddy_read_message" then buddy_read_path(notification.notifiable.buddy_read)
    end
  end

  def notification_url_for(notification)
    case notification.notification_type
    when "new_follower" then user_url(notification.actor)
    when "review_comment" then reading_url(notification.notifiable.reading)
    when "club_post" then club_url(notification.notifiable.club)
    when "buddy_read_invite" then buddy_read_url(notification.notifiable)
    when "buddy_read_message" then buddy_read_url(notification.notifiable.buddy_read)
    end
  end

  def notification_icon_for(notification)
    case notification.notification_type
    when "new_follower" then "fa-user-plus"
    when "review_comment" then "fa-comment"
    when "club_post" then "fa-people-group"
    when "buddy_read_invite" then "fa-people-arrows"
    when "buddy_read_message" then "fa-comments"
    end
  end
end
