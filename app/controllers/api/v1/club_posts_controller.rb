class Api::V1::ClubPostsController < Api::V1::BaseController
  before_action -> { require_scope!("write:clubs") }
  before_action :set_club

  def create
    @club_post = @club.club_posts.new(club_post_params.merge(user: current_user))
    authorize @club_post

    if @club_post.save
      render :show, status: :created
    else
      render json: {errors: @club_post.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    @club_post = @club.club_posts.find(params.expect(:id))
    authorize @club_post
    @club_post.destroy!
    head :no_content
  end

  private

  def set_club
    @club = Club.find(params.expect(:club_id))
  end

  def club_post_params
    params.expect(club_post: [:body, :spoiler])
  end
end
