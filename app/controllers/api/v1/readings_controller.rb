class Api::V1::ReadingsController < Api::V1::BaseController
  before_action :set_reading, only: %i[show update destroy]

  def index
    @readings = policy_scope(Reading)

    if params[:status].present? && Reading.statuses.key?(params[:status])
      @readings = @readings.where(status: params[:status])
    end

    @readings = @readings.order(updated_at: :desc)
    @pagy, @readings = pagy(@readings)
    fresh_when @readings
  end

  def show
    authorize @reading
    fresh_when @reading
  end

  def create
    @reading = Reading.new(reading_params.merge(user_id: current_user.id))
    authorize @reading

    if @reading.save
      render :show, status: :created
    else
      render json: {errors: @reading.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @reading
    if @reading.update(reading_params)
      render :show
    else
      render json: {errors: @reading.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    authorize @reading
    @reading.soft_delete
    head :no_content
  end

  private

  def set_reading
    @reading = Reading.with_deleted.find(params.expect(:id))
  end

  def reading_params
    params.expect(reading: [:book_id, :status, :rating, :review, :is_review_public, :started_on, :finished_on, :progress_percent, :format])
  end
end
