class BuddyReadMessagePolicy < ApplicationPolicy
  def create? = record.buddy_read.participant?(user)
end
