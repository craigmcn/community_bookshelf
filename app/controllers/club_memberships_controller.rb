class ClubMembershipsController < ApplicationController
  before_action :set_club

  def create
    @membership = @club.club_memberships.new(user: current_user)
    authorize @membership

    @membership.save
    redirect_to @club, notice: "You joined #{@club.name}."
  end

  def destroy
    @membership = @club.club_memberships.find_by!(user: current_user)
    authorize @membership

    @membership.destroy
    redirect_to @club, notice: "You left #{@club.name}.", status: :see_other
  end

  private

  def set_club
    @club = Club.find(params[:club_id])
  end
end
