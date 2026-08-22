class ReadingPolicy < ApplicationPolicy
  def show? = (!record.deleted? && (record.user == user || (record.is_review_public? && record.review.present?))) || user&.moderator_or_above?
  def edit? = !record.deleted? && (record.user == user || user&.moderator_or_above?)
  def create? = user.present?
  def update? = !record.deleted? && (record.user == user || user&.moderator_or_above?)
  def destroy? = !record.deleted? && user&.moderator_or_above?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.moderator_or_above?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
