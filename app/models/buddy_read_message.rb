class BuddyReadMessage < ApplicationRecord
  belongs_to :buddy_read
  belongs_to :user
  has_one :notification, as: :notifiable, dependent: :destroy

  validates :body, presence: true, length: {maximum: 1000}

  after_create :notify_other_participant

  private

  def notify_other_participant
    Notification.create!(
      recipient: buddy_read.other_participant(user),
      actor: user,
      notifiable: self,
      notification_type: :buddy_read_message
    )
  end
end
