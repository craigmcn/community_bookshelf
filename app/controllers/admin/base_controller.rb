class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    render_forbidden unless current_user&.admin?
  end

  def render_forbidden
    render plain: "Forbidden", status: :forbidden
  end
end
