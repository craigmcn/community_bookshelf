class Api::V1::ClubsController < Api::V1::BaseController
  before_action -> { require_scope!("read:clubs") }, only: %i[index show]
  before_action -> { require_scope!("write:clubs") }, only: %i[create update destroy]
  before_action :set_club, only: %i[show update destroy]

  def index
    authorize Club
    @clubs = policy_scope(Club).order(created_at: :desc)
    @member_counts = ClubMembership.where(club_id: @clubs.map(&:id)).group(:club_id).count
  end

  def show
    authorize @club
  end

  def create
    @club = Club.new(club_params.merge(created_by: current_user))
    authorize @club

    if @club.save
      render :show, status: :created
    else
      render json: {errors: @club.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @club
    if @club.update(club_params)
      render :show
    else
      render json: {errors: @club.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    authorize @club
    @club.destroy!
    head :no_content
  end

  private

  def set_club
    @club = Club.find(params.expect(:id))
  end

  def club_params
    params.expect(club: [:name, :description, :book_id])
  end
end
