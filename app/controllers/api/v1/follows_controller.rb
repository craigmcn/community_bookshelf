class Api::V1::FollowsController < Api::V1::BaseController
  before_action -> { require_scope!("write:follows") }
  before_action :set_followed_user

  def create
    @follow = Follow.new(follower: current_user, followed: @followed_user)
    authorize @follow

    if @follow.save
      render :show, status: :created
    else
      render json: {errors: @follow.errors.full_messages}, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    # The uniqueness validation above already covers the common case; this
    # catches the narrow race where a concurrent request wins between that
    # validation's SELECT and this one's INSERT, so it still gets a clean
    # 422 instead of an unhandled 500.
    render json: {errors: ["Followed has already been taken"]}, status: :unprocessable_content
  end

  # Idempotent, matching the HTML FollowsController — unfollowing twice (or
  # a relationship that never existed) is a no-op 204, not a 404, since a
  # non-existent follow and a just-removed one both end at "you're not
  # following this user" from the caller's point of view.
  def destroy
    @follow = current_user.active_follows.find_by(followed_id: @followed_user.id)
    if @follow
      authorize @follow
      @follow.destroy!
    end
    head :no_content
  end

  private

  def set_followed_user
    @followed_user = User.excluding_deleted_placeholder.find(params.expect(:user_id))
  end
end
