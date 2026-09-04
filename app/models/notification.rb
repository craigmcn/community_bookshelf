class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  enum :notification_type, {
    new_follower: "new_follower",
    review_comment: "review_comment",
    club_post: "club_post"
  }

  validates :notification_type, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  # Notifications not yet included in a digest email, regardless of whether
  # they've since been read in-app — a digest and an in-app read are tracked
  # independently so viewing the bell dropdown doesn't silently skip a
  # notification that would otherwise have been mailed.
  scope :not_yet_digested, -> { where(digested_at: nil) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  def message
    case notification_type
    when "new_follower" then "#{actor.display_name} started following you"
    when "review_comment" then "#{actor.display_name} commented on your review of #{notifiable.reading.book.title}"
    when "club_post" then "#{actor.display_name} posted in #{notifiable.club.name}"
    end
  end

  # Structured counterpart to NotificationsHelper#notification_path_for, for
  # the JSON API — a client can't follow a Rails path, so it gets a
  # resource type + id instead and builds its own request from that.
  def target_type
    case notification_type
    when "new_follower" then "user"
    when "review_comment" then "reading"
    when "club_post" then "club"
    else raise ArgumentError, "Unhandled notification_type: #{notification_type.inspect}"
    end
  end

  def target_id
    case notification_type
    when "new_follower" then actor_id
    when "review_comment" then notifiable.reading_id
    when "club_post" then notifiable.club_id
    else raise ArgumentError, "Unhandled notification_type: #{notification_type.inspect}"
    end
  end
end
