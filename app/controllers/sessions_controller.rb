class SessionsController < Clearance::SessionsController
  # Custom Clearance Session handling

  private

  def url_after_create
    current_user.admin? ? admin_root_path : root_path
  end
end
