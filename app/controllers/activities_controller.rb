class ActivitiesController < ApplicationController
  def index
    @activities = Activity.where(user: current_user.following)
      .includes(:user, reading: :book)
      .order(created_at: :desc)
    @pagy, @activities = pagy(@activities)
  end
end
