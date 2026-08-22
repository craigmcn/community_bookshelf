class ReviewLikesController < ApplicationController
  before_action :set_reading

  def create
    @review_like = ReviewLike.new(user: current_user, reading: @reading)
    authorize @review_like

    @review_like.save
    redirect_to @reading
  end

  def destroy
    @review_like = current_user.review_likes.find_by(reading_id: @reading.id)
    if @review_like
      authorize @review_like
      @review_like.destroy
    end

    redirect_to @reading, status: :see_other
  end

  private

  def set_reading
    @reading = Reading.find(params[:reading_id])
  end
end
