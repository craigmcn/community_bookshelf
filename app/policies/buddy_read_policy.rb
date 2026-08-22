class BuddyReadPolicy < ApplicationPolicy
  def index? = user.present?
  def show? = record.participant?(user)
  def create? = user.present?

  # update? backs accept/decline (partner only) and cancel (either participant)
  def update? = record.participant?(user)
  def destroy? = record.participant?(user)

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(initiator: user).or(scope.where(partner: user))
    end
  end
end
