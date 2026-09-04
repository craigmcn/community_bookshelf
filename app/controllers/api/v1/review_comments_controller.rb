class Api::V1::ReviewCommentsController < Api::V1::BaseController
  before_action -> { require_scope!("write:review_comments") }
  before_action :set_reading

  def create
    @review_comment = @reading.review_comments.new(review_comment_params.merge(user: current_user))
    authorize @review_comment

    if @review_comment.save
      render :show, status: :created
    else
      render json: {errors: @review_comment.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    @review_comment = @reading.review_comments.find(params.expect(:id))
    authorize @review_comment
    @review_comment.destroy!
    head :no_content
  end

  private

  def set_reading
    @reading = Reading.find(params.expect(:reading_id))
  end

  def review_comment_params
    params.expect(review_comment: [:body])
  end
end
