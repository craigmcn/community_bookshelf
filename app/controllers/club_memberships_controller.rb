class ClubMembershipsController < ApplicationController
  before_action :set_club

  def create
    @membership = @club.club_memberships.new(user: current_user)
    authorize @membership

    if @membership.save
      redirect_to @club, notice: "You joined #{@club.name}."
    else
      redirect_to @club
    end
  end

  def destroy
    @membership = @club.club_memberships.find_by(user: current_user)
    if @membership
      authorize @membership
      @membership.destroy
    end

    redirect_to @club, notice: "You left #{@club.name}.", status: :see_other
  end

  private

  def set_club
    @club = Club.find(params[:club_id])
  end
end
