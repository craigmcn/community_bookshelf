class ReadingPolicy < ApplicationPolicy
  def show?    = record.user == user || user&.moderator? || user&.admin?
  def edit?    = record.user == user || user&.admin?
  def create?  = user.present?
  def update?  = record.user == user || user&.admin?
  def destroy? = record.user == user || user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)  # members see only their own
    end
  end
end
