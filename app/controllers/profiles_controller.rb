class ProfilesController < ApplicationController
  before_action :set_profile_user

  def show
    readings = Reading.where(user: @profile_user)
    @finished_count = readings.finished.count
    @currently_reading_count = readings.reading.count
    @public_reviews = readings.where(is_review_public: true).where.not(review: [nil, ""])
      .includes(:book).order(updated_at: :desc).limit(5)
    @current_streak = @profile_user.current_streak
    @badges = @profile_user.badges
    @current_year_challenge = @profile_user.current_year_challenge
  end

  def followers
    @users = @profile_user.followers.excluding_deleted_placeholder.with_attached_avatar.order(:name)
  end

  def following
    @users = @profile_user.following.excluding_deleted_placeholder.with_attached_avatar.order(:name)
  end

  private

  def set_profile_user
    @profile_user = User.excluding_deleted_placeholder.find(params[:id])
    authorize @profile_user, :show?
  end
end
