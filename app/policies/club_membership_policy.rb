class ClubMembershipPolicy < ApplicationPolicy
  def create? = user.present? && !record.club.member?(user)
  def destroy? = record.user == user
end
