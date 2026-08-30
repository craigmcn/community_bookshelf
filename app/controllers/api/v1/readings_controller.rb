class Api::V1::ReadingsController < Api::V1::BaseController
  before_action :set_reading, only: %i[show update destroy]

  # Caps a single bulk request well below the 120/min token throttle, so one
  # request can't be used to dodge rate limiting by front-loading a huge batch.
  MAX_BULK_SIZE = 100

  def index
    @readings = policy_scope(Reading)

    if params[:status].present? && Reading.statuses.key?(params[:status])
      @readings = @readings.where(status: params[:status])
    end

    @readings = @readings.order(updated_at: :desc)
    @pagy, @readings = pagy(@readings)
  end

  def show
    authorize @reading
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

  # Accepts { "readings": [{...}, {...}, ...] } and creates each independently
  # — one request, N readings, rather than N individual POST /readings calls
  # each burning its own slot against the rate limit. Each row succeeds or
  # fails on its own; a bad row doesn't roll back the ones that saved.
  def bulk
    raw_readings = params[:readings]

    if !raw_readings.is_a?(Array) || raw_readings.empty?
      return render json: {errors: ["readings must be a non-empty array"]}, status: :unprocessable_content
    end

    if raw_readings.size > MAX_BULK_SIZE
      return render json: {errors: ["readings cannot contain more than #{MAX_BULK_SIZE} items"]}, status: :unprocessable_content
    end

    permitted_readings = params.expect(readings: [bulk_reading_keys])

    @results = permitted_readings.map.with_index do |attrs, index|
      reading = Reading.new(attrs.to_h.merge(user_id: current_user.id))

      if !ReadingPolicy.new(current_user, reading).create?
        {index: index, status: "error", errors: ["You are not authorized to perform this action."]}
      elsif reading.save
        {index: index, status: "created", reading: reading}
      else
        {index: index, status: "error", errors: reading.errors.full_messages}
      end
    end
  end

  private

  def set_reading
    @reading = Reading.with_deleted.find(params.expect(:id))
  end

  def reading_params
    params.expect(reading: bulk_reading_keys)
  end

  def bulk_reading_keys
    [:book_id, :status, :rating, :review, :is_review_public, :started_on, :finished_on, :progress_percent, :format]
  end
end
