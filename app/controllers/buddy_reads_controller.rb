class BuddyReadsController < ApplicationController
  before_action :set_buddy_read, only: [:show, :update]

  def index
    authorize BuddyRead, :index?
    @buddy_reads = policy_scope(BuddyRead).includes(:book, :initiator, :partner).order(created_at: :desc)
  end

  def new
    authorize BuddyRead, :create?
    @buddy_read = BuddyRead.new
    @partners = User.excluding_deleted_placeholder.where.not(id: current_user.id).order(:name)
    @books = Book.order(:title)
  end

  def create
    @buddy_read = BuddyRead.new(buddy_read_params.merge(initiator: current_user, status: "pending"))
    authorize @buddy_read

    if @buddy_read.save
      redirect_to @buddy_read, notice: "Buddy read invitation sent."
    else
      @partners = User.excluding_deleted_placeholder.where.not(id: current_user.id).order(:name)
      @books = Book.order(:title)
      render :new, status: :unprocessable_content
    end
  end

  def show
    authorize @buddy_read
    @buddy_read = BuddyRead.includes(:book, :initiator, :partner).find(@buddy_read.id)
    @messages = @buddy_read.messages.includes(:user).order(created_at: :asc)
    @message = BuddyReadMessage.new
  end

  def update
    authorize @buddy_read

    case params[:status]
    when "accepted", "declined"
      if @buddy_read.pending? && @buddy_read.partner == current_user
        @buddy_read.update(status: params[:status])
      end
    when "cancelled"
      @buddy_read.update(status: "cancelled") if @buddy_read.pending? || @buddy_read.accepted?
    when "completed"
      @buddy_read.update(status: "completed") if @buddy_read.accepted?
    end

    redirect_to @buddy_read
  end

  private

  def set_buddy_read
    @buddy_read = BuddyRead.find(params[:id])
  end

  def buddy_read_params
    params.expect(buddy_read: [:book_id, :partner_id])
  end
end
