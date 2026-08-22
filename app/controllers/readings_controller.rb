class ReadingsController < ApplicationController
  before_action :set_reading, only: %i[show edit update destroy]

  SORT_OPTIONS = {
    "recent" => {label: "Recently Updated", order: {updated_at: :desc}},
    "title" => {label: "Book Title", order: {"books.title": :asc}},
    "rating" => {label: "Rating (high to low)", order: {rating: :desc}}
  }.freeze

  def index
    @readings = current_user.readings.includes(:book).joins(:book)

    if params[:q].present?
      query = "%#{params[:q].strip}%"
      @readings = @readings.where("books.title ILIKE :q OR books.author ILIKE :q", q: query)
    end

    if params[:status].present? && Reading.statuses.key?(params[:status])
      @readings = @readings.where(status: params[:status])
    end

    if params[:rating].present? && Reading.ratings.key?(params[:rating])
      @readings = @readings.where(rating: params[:rating])
    end

    if params[:tag].present?
      @tag = Tag.find_by(name: params[:tag].to_s.strip.downcase)
      @readings = @tag ? @readings.merge(Book.joins(:tags).where(tags: {id: @tag.id})) : @readings.none
    end

    @sort = SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : "recent"
    @readings = @readings.order(SORT_OPTIONS[@sort][:order])

    @shelf_tags = Tag.genre.joins(books: :readings).where(readings: {user: current_user}).distinct.order(:name)

    @pagy, @readings = pagy(@readings)
    @recommended_books = Book.recommended_for(current_user)
  end

  def show
    authorize @reading
    @review_comments = @reading.review_comments.includes(:user)
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
