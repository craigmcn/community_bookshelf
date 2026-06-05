class BookPolicy < ApplicationPolicy
  def index?   = true          # public
  def show?    = true          # public
  def create?  = user.present? # any signed-in user
  def update?  = user&.moderator_or_above?
  def destroy? = user&.moderator_or_above?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all  # books are public
    end
  end
end
