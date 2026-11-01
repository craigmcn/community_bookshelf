class Admin::ReadingsController < Admin::BaseController
  def index
    @readings = Reading.with_deleted.where.not(review: [nil, ""])
      .includes(:user, :book)
      .order(updated_at: :desc)
  end

  # Separate from ReadingsController#destroy so moderating from this list keeps
  # the moderator here (row faded in place) instead of redirecting to their own shelf.
  def destroy
    @reading = Reading.with_deleted.find(params.expect(:id))
    authorize @reading
    soft_delete_reading!(@reading)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@reading, partial: "admin/readings/reading", locals: {reading: @reading}) }
      format.html { redirect_to admin_readings_path, notice: "Reading was removed.", status: :see_other }
    end
  end
end
