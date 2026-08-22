class FollowsController < ApplicationController
  before_action :set_followed_user

  def create
    @follow = Follow.new(follower: current_user, followed: @followed_user)
    authorize @follow

    @follow.save
    redirect_to @followed_user, notice: "You're now following #{@followed_user.display_name}."
  end

  def destroy
    @follow = current_user.active_follows.find_by!(followed_id: @followed_user.id)
    authorize @follow

    @follow.destroy
    redirect_to @followed_user, notice: "Unfollowed #{@followed_user.display_name}.", status: :see_other
  end

  private

  def set_followed_user
    @followed_user = User.excluding_deleted_placeholder.find(params[:user_id])
  end
end
