class ShelfPolicy < ApplicationPolicy
  # Shelves are personal book-collection lists, not moderated content — unlike
  # readings, moderators/admins do NOT get blanket access to other users' shelves.
  def show? = record.user == user
  def create? = user.present?
  def update? = record.user == user
  def destroy? = record.user == user

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
