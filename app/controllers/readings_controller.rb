class ReadingsController < ApplicationController
  before_action :set_reading, only: %i[ show edit update destroy ]

  # GET /readings or /readings.json
  def index
    @readings = current_user.readings
  end

  # GET /readings/1 or /readings/1.json
  def show
  end

  # GET /readings/new
  def new
    @reading = Reading.new(book_id: params[:book_id])
  end

  # GET /readings/1/edit
  def edit
  end

  # POST /readings or /readings.json
  def create
    @reading = Reading.new(reading_params)

    respond_to do |format|
      if @reading.save
        format.html { redirect_to @reading, notice: "Reading was successfully created." }
        format.json { render :show, status: :created, location: @reading }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @reading.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /readings/1 or /readings/1.json
  def update
    respond_to do |format|
      if @reading.update(reading_params)
        format.html { redirect_to @reading, notice: "Reading was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @reading }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @reading.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /readings/1 or /readings/1.json
  def destroy
    @reading.destroy!

    respond_to do |format|
      format.html { redirect_to readings_path, notice: "Reading was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reading
      @reading = Reading.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def reading_params
      params.expect(reading: [ :user_id, :book_id, :status, :rating, :review ])
    end
end
