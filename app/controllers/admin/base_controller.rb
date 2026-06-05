class Admin::BaseController < ApplicationController
  before_action :require_moderator_or_above

  private

  def require_moderator_or_above
    render_forbidden unless current_user&.moderator_or_above?
  end

  def require_admin
    render_forbidden unless current_user&.admin?
  end

  def render_forbidden
    render plain: "Forbidden", status: :forbidden
  end
end
