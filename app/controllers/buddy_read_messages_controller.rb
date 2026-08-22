class BuddyReadMessagesController < ApplicationController
  before_action :set_buddy_read

  def create
    @message = @buddy_read.messages.new(message_params.merge(user: current_user))
    authorize @message

    if @message.save
      redirect_to @buddy_read
    else
      redirect_to @buddy_read, alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_buddy_read
    @buddy_read = BuddyRead.find(params[:buddy_read_id])
  end

  def message_params
    params.expect(buddy_read_message: [:body])
  end
end
