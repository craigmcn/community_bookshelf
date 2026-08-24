class ReviewComment < ApplicationRecord
  belongs_to :user
  belongs_to :reading
  has_one :notification, as: :notifiable, dependent: :destroy

  validates :body, presence: true, length: {maximum: 1000}

  after_create :notify_reading_owner

  private

  def notify_reading_owner
    return if reading.user_id == user_id

    Notification.create!(recipient: reading.user, actor: user, notifiable: self, notification_type: :review_comment)
  end
end
