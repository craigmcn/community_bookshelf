class BooksController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  before_action :set_book, only: %i[show edit update destroy]

  SORT_OPTIONS = {
    "title" => {label: "Title", order: {title: :asc}},
    "author" => {label: "Author", order: {author: :asc, title: :asc}},
    "newest" => {label: "Recently Added", order: {created_at: :desc}},
    "published" => {label: "Publication Date", order: {published_on: :desc}}
  }.freeze

  def index
    @books = policy_scope(Book).includes(:added_by)
    @genre_tags = Tag.genre.order(:name)
    @mood_tags = Tag.mood.order(:name)
    @pace_tags = Tag.pace.order(:name)

    if params[:q].present?
      query = "%#{params[:q].strip}%"
      @books = @books.where("books.title ILIKE :q OR books.author ILIKE :q", q: query)
    end

    if params[:tag].present?
      @tag = Tag.find_by(name: params[:tag].to_s.strip.downcase)
      @books = @tag ? @books.joins(:tags).where(tags: {id: @tag.id}) : @books.none
    end

    @sort = SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : "title"
    @books = @books.order(SORT_OPTIONS[@sort][:order])

    @pagy, @books = pagy(@books)
  end

  def show
    authorize @book
    @user_readings = current_user ? current_user.readings.where(book: @book).order(created_at: :desc).to_a : Reading.none
    @user_shelves = current_user&.shelves&.order(:name)
    @shelf_ids_with_book = current_user&.shelves&.joins(:shelf_books)
      &.where(shelf_books: {book_id: @book.id})&.pluck(:id) || []
    @similar_books = @book.similar_books
  end

  def new
    @book = Book.new
  end

  def edit
    authorize @book
  end

  def create
    @book = Book.new(book_params.merge(added_by: current_user))
    authorize @book

    detail = OpenLibraryService.work_detail(@book.open_library_key)
    @book.description = detail[:description] if detail[:description].present?
    @book.subjects = detail[:subjects] if detail[:subjects].present?

    if @book.save
      redirect_to @book, notice: "Book was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @book
    if @book.update(book_params)
      redirect_to @book, notice: "Book was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @book
    title = @book.title

    ActiveRecord::Base.transaction do
      @book.destroy!
      log_audit_action!(action: "destroy_book", subject: @book, details: {title: title})
    end

    redirect_to books_path, notice: "Book was successfully destroyed.", status: :see_other
  end

  private

  def set_book
    @book = Book.find(params.expect(:id))
  end

  def book_params
    params.expect(book: [:title, :author, :cover_url, :isbn, :page_count, :published_on, :open_library_key, :series_id, :series_position, :tag_list, :mood_list, :pace_list])
  end
end
