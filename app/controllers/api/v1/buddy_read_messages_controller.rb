class Api::V1::BuddyReadMessagesController < Api::V1::BaseController
  before_action -> { require_scope!("write:buddy_reads") }
  before_action :set_buddy_read

  def create
    @message = @buddy_read.messages.new(message_params.merge(user: current_user))
    authorize @message

    if @message.save
      render :show, status: :created
    else
      render json: {errors: @message.errors.full_messages}, status: :unprocessable_content
    end
  end

  private

  def set_buddy_read
    @buddy_read = BuddyRead.find(params.expect(:buddy_read_id))
  end

  def message_params
    params.expect(buddy_read_message: [:body])
  end
end
