require "csv"

class ReadingsController < ApplicationController
  before_action :set_reading, only: %i[show edit update destroy reread]

  SORT_OPTIONS = {
    "recent" => {label: "Recently Updated", order: {updated_at: :desc}},
    "title" => {label: "Book Title", order: {"books.title": :asc}},
    # rating is nullable ("No rating"); Postgres' DESC puts NULLs first, burying the rated readings.
    "rating" => {label: "Rating (high to low)", order: Arel.sql("readings.rating DESC NULLS LAST")}
  }.freeze

  def index
    @readings = current_user.readings.includes(:book).joins(:book)
    # Only filters that actually narrowed the query; unknown status/rating values are ignored below.
    @filters_applied = false

    if params[:q].present?
      query = "%#{params[:q].strip}%"
      @readings = @readings.where("books.title ILIKE :q OR books.author ILIKE :q", q: query)
      @filters_applied = true
    end

    if params[:status].present? && Reading.statuses.key?(params[:status])
      @readings = @readings.where(status: params[:status])
      @filters_applied = true
    end

    if params[:rating].present? && Reading.ratings.key?(params[:rating])
      @readings = @readings.where(rating: params[:rating])
      @filters_applied = true
    end

    if params[:tag].present?
      @tag = Tag.find_by(name: params[:tag].to_s.strip.downcase)
      @readings = @tag ? @readings.merge(Book.joins(:tags).where(tags: {id: @tag.id})) : @readings.none
      @filters_applied = true
    end

    @sort = SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : "recent"
    # Unique tiebreaker: tied rows (e.g. every unrated reading) can otherwise shift between Pagy's pages.
    @readings = @readings.order(SORT_OPTIONS[@sort][:order]).order(id: :desc)

    @shelf_tags = Tag.genre.joins(books: :readings).where(readings: {user: current_user}).distinct.order(:name)

    @pagy, @readings = pagy(@readings)
    @recommended_books = Book.recommended_for(current_user)
  end

  def export
    readings = current_user.readings.includes(:book).order(:created_at)

    csv = CSV.generate(headers: true) do |csv|
      csv << ["Title", "Author", "ISBN", "Status", "Rating", "Format", "Started On", "Finished On", "Progress Percent", "Review", "Review Public", "Date Added"]
      readings.each do |reading|
        csv << [
          reading.book.title,
          reading.book.author,
          reading.book.isbn,
          reading.status_label,
          Reading.ratings[reading.rating],
          reading.format,
          reading.started_on,
          reading.finished_on,
          reading.progress_percent,
          reading.review,
          reading.is_review_public,
          reading.created_at.to_date
        ]
      end
    end

    send_data csv, filename: "my-shelf-#{Date.current.iso8601}.csv", type: "text/csv"
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

  # The shelf row's one-click re-read; the book page's "Log a Re-read" link goes through #new instead.
  def reread
    authorize @reading
    current_user.readings.create!(book: @reading.book, status: :want_to_read)
    redirect_to readings_path, notice: "Started a re-read of \"#{@reading.book.title}\".", status: :see_other
  end

  def destroy
    authorize @reading
    soft_delete_reading!(@reading)
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
