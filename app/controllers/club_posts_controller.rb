class ClubPostsController < ApplicationController
  before_action :set_club

  def create
    @club_post = @club.club_posts.new(club_post_params.merge(user: current_user))
    authorize @club_post

    if @club_post.save
      redirect_to @club
    else
      redirect_to @club, alert: @club_post.errors.full_messages.to_sentence
    end
  end

  def destroy
    @club_post = @club.club_posts.find(params[:id])
    authorize @club_post

    @club_post.destroy
    redirect_to @club, notice: "Post removed.", status: :see_other
  end

  private

  def set_club
    @club = Club.find(params[:club_id])
  end

  def club_post_params
    params.expect(club_post: [:body, :spoiler])
  end
end
