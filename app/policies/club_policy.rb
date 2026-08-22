class ClubPolicy < ApplicationPolicy
  def index? = user.present?
  def show? = user.present?
  def create? = user.present?
  def update? = record.created_by == user || user&.moderator_or_above?
  def destroy? = record.created_by == user || user&.moderator_or_above?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
