class ReadingPolicy < ApplicationPolicy
  def create?  = user.present?
  def update?  = record.user == user || user&.admin?
  def destroy? = record.user == user || user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)  # members see only their own
    end
  end
end
