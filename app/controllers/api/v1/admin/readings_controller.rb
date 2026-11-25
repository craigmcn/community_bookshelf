# Removing one is DELETE /readings/:id, which already audits moderator deletes.
class Api::V1::Admin::ReadingsController < Api::V1::Admin::BaseController
  def index
    @readings = Reading.reviewed_including_deleted.includes(:user, :book)
  end
end
