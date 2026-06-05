class Admin::ReadingsController < Admin::BaseController
  def index
    @readings = Reading.where.not(review: [nil, ""])
      .includes(:user, :book)
      .order(updated_at: :desc)
  end
end
