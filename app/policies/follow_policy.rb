class FollowPolicy < ApplicationPolicy
  def create? = user.present? && record.follower == user && record.followed != user
  def destroy? = record.follower == user
end
