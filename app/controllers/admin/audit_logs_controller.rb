class Admin::AuditLogsController < Admin::BaseController
  before_action :require_admin

  def index
    @pagy, @audit_logs = pagy(AuditLog.recent.includes(:actor))
  end
end
