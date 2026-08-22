class BuddyRead < ApplicationRecord
  belongs_to :book
  belongs_to :initiator, class_name: "User"
  belongs_to :partner, class_name: "User"
  has_many :messages, class_name: "BuddyReadMessage", dependent: :destroy

  enum :status, {pending: "pending", accepted: "accepted", declined: "declined", cancelled: "cancelled", completed: "completed"}, default: "pending"

  validate :initiator_and_partner_are_distinct

  def participant?(user)
    user && (initiator_id == user.id || partner_id == user.id)
  end

  def other_participant(user)
    (user.id == initiator_id) ? partner : initiator
  end

  # Declining or cancelling ends the pairing — a thread with no active or
  # completed relationship behind it shouldn't keep accepting new messages.
  def messageable?
    !declined? && !cancelled?
  end

  private

  def initiator_and_partner_are_distinct
    errors.add(:partner_id, "can't be yourself") if initiator_id.present? && initiator_id == partner_id
  end
end
