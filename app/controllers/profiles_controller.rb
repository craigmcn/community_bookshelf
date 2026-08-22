class ProfilesController < ApplicationController
  def show
    @profile_user = User.excluding_deleted_placeholder.find(params[:id])
    authorize @profile_user

    readings = Reading.where(user: @profile_user)
    @finished_count = readings.finished.count
    @currently_reading_count = readings.reading.count
    @public_reviews = readings.where(is_review_public: true).where.not(review: [nil, ""])
      .includes(:book).order(updated_at: :desc).limit(5)
  end
end
