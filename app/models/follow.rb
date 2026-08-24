class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  has_one :notification, as: :notifiable, dependent: :destroy

  validates :followed_id, uniqueness: {scope: :follower_id}
  validate :cannot_follow_self

  after_create :notify_followed_user

  private

  def cannot_follow_self
    errors.add(:followed_id, "can't be yourself") if follower_id.present? && follower_id == followed_id
  end

  def notify_followed_user
    Notification.create!(recipient: followed, actor: follower, notifiable: self, notification_type: :new_follower)
  end
end
