class ReviewCommentsController < ApplicationController
  before_action :set_reading

  def create
    @review_comment = @reading.review_comments.new(review_comment_params.merge(user: current_user))
    authorize @review_comment

    if @review_comment.save
      redirect_to @reading, notice: "Comment posted."
    else
      redirect_to @reading, alert: @review_comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @review_comment = @reading.review_comments.find(params[:id])
    authorize @review_comment

    @review_comment.destroy
    redirect_to @reading, notice: "Comment removed.", status: :see_other
  end

  private

  def set_reading
    @reading = Reading.find(params[:reading_id])
  end

  def review_comment_params
    params.expect(review_comment: [:body])
  end
end
