class SeriesPolicy < ApplicationPolicy
  def index? = true          # public
  def show? = true          # public
  def create? = user&.moderator_or_above?
  def update? = user&.moderator_or_above?
  def destroy? = user&.moderator_or_above?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all  # series are public
    end
  end
end
