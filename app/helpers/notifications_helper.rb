module NotificationsHelper
  def notification_path_for(notification)
    case notification.notification_type
    when "new_follower" then user_path(notification.actor)
    when "review_comment" then reading_path(notification.notifiable.reading)
    when "club_post" then club_path(notification.notifiable.club)
    end
  end

  def notification_url_for(notification)
    case notification.notification_type
    when "new_follower" then user_url(notification.actor)
    when "review_comment" then reading_url(notification.notifiable.reading)
    when "club_post" then club_url(notification.notifiable.club)
    end
  end

  def notification_icon_for(notification)
    case notification.notification_type
    when "new_follower" then "fa-user-plus"
    when "review_comment" then "fa-comment"
    when "club_post" then "fa-people-group"
    end
  end
end
