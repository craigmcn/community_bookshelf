class ApiTokenPolicy < ApplicationPolicy
  def index? = user.present?
  def create? = user.present? && record.user == user
  def destroy? = record.user == user

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
