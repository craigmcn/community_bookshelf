class Admin::ReadingsController < Admin::BaseController
  def index
    @readings = Reading.with_deleted.where.not(review: [nil, ""])
      .includes(:user, :book)
      .order(updated_at: :desc)
  end
end
