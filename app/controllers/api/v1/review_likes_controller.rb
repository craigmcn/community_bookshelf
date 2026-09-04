class Api::V1::ReviewLikesController < Api::V1::BaseController
  before_action -> { require_scope!("write:review_likes") }
  before_action :set_reading

  def create
    @review_like = ReviewLike.new(user: current_user, reading: @reading)
    authorize @review_like

    if @review_like.save
      render :show, status: :created
    else
      render json: {errors: @review_like.errors.full_messages}, status: :unprocessable_content
    end
  end

  # Idempotent, matching the HTML ReviewLikesController — unliking twice (or
  # a like that never existed) is a no-op 204, same pattern as unfollow/#155
  # and leaving a club/#168.
  def destroy
    @review_like = current_user.review_likes.find_by(reading_id: @reading.id)
    if @review_like
      authorize @review_like
      @review_like.destroy!
    end
    head :no_content
  end

  private

  def set_reading
    @reading = Reading.find(params.expect(:reading_id))
  end
end
