class Api::V1::ClubMembershipsController < Api::V1::BaseController
  before_action -> { require_scope!("write:clubs") }
  before_action :set_club

  def create
    @membership = @club.club_memberships.new(user: current_user)
    authorize @membership

    if @membership.save
      render "api/v1/clubs/show", status: :created
    else
      render json: {errors: @membership.errors.full_messages}, status: :unprocessable_content
    end
  end

  # Idempotent, matching the HTML ClubMembershipsController — leaving a club
  # you're not a member of is a no-op 204, same pattern as unfollow/#155.
  def destroy
    @membership = @club.club_memberships.find_by(user: current_user)
    if @membership
      authorize @membership
      @membership.destroy!
    end
    head :no_content
  end

  private

  def set_club
    @club = Club.find(params.expect(:club_id))
  end
end
