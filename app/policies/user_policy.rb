class UserPolicy < ApplicationPolicy
  # Backs AccountsController, which only ever loads current_user (never a
  # params[:id]) — these checks exist to pin that invariant with the same
  # authorization layer every other model in this app uses, not because the
  # controller branches on ownership today.
  def edit? = record == user
  def update? = record == user
  def destroy? = record == user
end
