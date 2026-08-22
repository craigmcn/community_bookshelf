class ClubsController < ApplicationController
  before_action :set_club, only: [:show, :edit, :update, :destroy]

  def index
    authorize Club
    @clubs = policy_scope(Club).includes(:book).order(created_at: :desc)
    @member_counts = ClubMembership.where(club_id: @clubs.map(&:id)).group(:club_id).count
  end

  def show
    authorize @club
    @club_posts = @club.club_posts.includes(:user)
    @club_post = ClubPost.new
    @viewer_has_finished_book = Reading.exists?(user_id: current_user.id, book_id: @club.book_id, status: :finished)
  end

  def new
    authorize Club, :create?
    @club = Club.new
    @books = Book.order(:title)
  end

  def create
    @club = Club.new(club_params.merge(created_by: current_user))
    authorize @club

    if @club.save
      redirect_to @club, notice: "Club created."
    else
      @books = Book.order(:title)
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @club
    @books = Book.order(:title)
  end

  def update
    authorize @club
    if @club.update(club_params)
      redirect_to @club, notice: "Club updated."
    else
      @books = Book.order(:title)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @club
    @club.destroy
    redirect_to clubs_path, notice: "Club deleted.", status: :see_other
  end

  private

  def set_club
    @club = Club.find(params[:id])
  end

  def club_params
    params.expect(club: [:name, :description, :book_id])
  end
end
