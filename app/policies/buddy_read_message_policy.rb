class BuddyReadMessagePolicy < ApplicationPolicy
  def create? = record.buddy_read.participant?(user) && record.buddy_read.messageable?
end
