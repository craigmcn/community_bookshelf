class ClubPostPolicy < ApplicationPolicy
  def create? = record.club.member?(user)
  def destroy? = record.user == user || user&.moderator_or_above?
end
