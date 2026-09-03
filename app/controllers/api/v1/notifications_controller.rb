class Api::V1::NotificationsController < Api::V1::BaseController
  before_action -> { require_scope!("read:notifications") }, only: %i[index]
  before_action -> { require_scope!("write:notifications") }, only: %i[update mark_all_read]

  # No policy class: inherently scoped to current_user, same pattern as the
  # HTML NotificationsController.
  def index
    @notifications = current_user.notifications.includes(:actor, :notifiable).recent
    @pagy, @notifications = pagy(@notifications)
  end

  # Renders the notification's own JSON rather than the HTML controller's
  # redirect-to-underlying-resource — a script marking a notification read
  # just needs confirmation of the new read_at, not a redirect.
  def update
    @notification = current_user.notifications.find(params.expect(:id))
    @notification.mark_read!
    render :show
  end

  def mark_all_read
    count = current_user.notifications.unread.update_all(read_at: Time.current)
    render json: {marked_read: count}
  end
end
