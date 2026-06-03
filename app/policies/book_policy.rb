class BookPolicy < ApplicationPolicy
  def index?   = true          # public
  def show?    = true          # public
  def create?  = user.present? # any signed-in user
  def update?  = moderator_or_above?
  def destroy? = moderator_or_above?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all  # books are public
    end
  end

  private

  def moderator_or_above?
    user&.moderator? || user&.admin?
  end
end
