class ReadingsController < ApplicationController
  before_action :set_reading, only: %i[show edit update destroy]

  def index
    @readings = current_user.readings.includes(:book)
  end

  def show
    authorize @reading
  end

  def new
    @reading = Reading.new(book_id: params[:book_id])
  end

  def edit
    authorize @reading
  end

  def create
    @reading = Reading.new(reading_params.merge(user_id: current_user.id))
    authorize @reading

    if @reading.save
      redirect_to @reading, notice: "Reading was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @reading
    if @reading.update(reading_params)
      redirect_to @reading, notice: "Reading was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @reading
    @reading.soft_delete
    redirect_to readings_path, notice: "Reading was removed.", status: :see_other
  end

  private

  def set_reading
    @reading = Reading.with_deleted.find(params.expect(:id))
  end

  def reading_params
    params.expect(reading: [:book_id, :status, :rating, :review, :is_review_public, :started_on, :finished_on, :progress_percent, :format])
  end
end
