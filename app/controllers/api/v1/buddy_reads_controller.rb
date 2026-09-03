class Api::V1::BuddyReadsController < Api::V1::BaseController
  before_action -> { require_scope!("read:buddy_reads") }, only: %i[index show]
  before_action -> { require_scope!("write:buddy_reads") }, only: %i[create update]
  before_action :set_buddy_read, only: %i[show update]

  def index
    authorize BuddyRead, :index?
    @buddy_reads = policy_scope(BuddyRead).includes(:book, :initiator, :partner).order(created_at: :desc)
  end

  def create
    @buddy_read = BuddyRead.new(buddy_read_params.merge(initiator: current_user, status: "pending"))
    authorize @buddy_read

    if @buddy_read.save
      load_show_data
      render :show, status: :created
    else
      render json: {errors: @buddy_read.errors.full_messages}, status: :unprocessable_content
    end
  end

  def show
    authorize @buddy_read
    load_show_data
  end

  # Unlike the HTML controller, an invalid status transition renders a 422
  # with an explanatory error rather than silently no-opping — a script
  # needs to know its request didn't do anything, where a redirect-back
  # is enough feedback for a human clicking a button that shouldn't be there.
  def update
    authorize @buddy_read

    new_status = params[:status]
    case new_status
    when "accepted", "declined"
      if @buddy_read.pending? && @buddy_read.partner == current_user
        @buddy_read.update!(status: new_status)
      else
        return render json: {errors: ["Only the partner can accept or decline a pending invitation"]}, status: :unprocessable_content
      end
    when "cancelled"
      if @buddy_read.pending? || @buddy_read.accepted?
        @buddy_read.update!(status: "cancelled")
      else
        return render json: {errors: ["Can only cancel a pending or accepted buddy read"]}, status: :unprocessable_content
      end
    when "completed"
      if @buddy_read.accepted?
        @buddy_read.update!(status: "completed")
      else
        return render json: {errors: ["Can only complete an accepted buddy read"]}, status: :unprocessable_content
      end
    else
      return render json: {errors: ["Invalid status: #{new_status.inspect}"]}, status: :unprocessable_content
    end

    load_show_data
    render :show
  end

  private

  def set_buddy_read
    @buddy_read = BuddyRead.find(params.expect(:id))
  end

  # Re-queried with eager-loaded associations after authorize succeeds,
  # rather than in set_buddy_read — set_buddy_read is shared with update's
  # failure paths above, which never render those associations, and an
  # unauthorized show/update errors out before rendering too. Matches the
  # HTML BuddyReadsController#show's same tradeoff.
  def load_show_data
    @buddy_read = BuddyRead.includes(:book, :initiator, :partner).find(@buddy_read.id)
    @messages = @buddy_read.messages.includes(:user).order(created_at: :asc)
  end

  def buddy_read_params
    params.expect(buddy_read: [:book_id, :partner_id])
  end
end
