class BooksController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  before_action :set_book, only: %i[show edit update destroy]

  # Each order ends with an id tiebreaker in its own direction, so tied rows (e.g. undated
  # books) can't shift between Pagy's pages and "newest" stays newest-first even on a tie.
  SORT_OPTIONS = {
    "title" => {label: "Title", order: {title: :asc, id: :asc}},
    "author" => {label: "Author", order: {author: :asc, title: :asc, id: :asc}},
    "newest" => {label: "Recently Added", order: {created_at: :desc, id: :desc}},
    # published_on is a brand-new optional field most books won't have yet; NULLS LAST keeps
    # undated books from crowding out the ones that actually have a date (Postgres' default
    # DESC puts NULLs first), matching SeriesController#show's NULLS LAST ordering.
    "published" => {label: "Publication Date", order: Arel.sql("books.published_on DESC NULLS LAST, books.id DESC")}
  }.freeze

  def index
    @books = policy_scope(Book).includes(:added_by)
    @genre_tags = Tag.genre.order(:name)
    @mood_tags = Tag.mood.order(:name)
    @pace_tags = Tag.pace.order(:name)

    @query = search_query
    if @query
      query = "%#{@query}%"
      @books = @books.where("books.title ILIKE :q OR books.author ILIKE :q", q: query)
    end

    # Only a string tag is a filter (and echoed back); a hash one is ignored, like a hash q.
    @tag_query = params[:tag].strip if params[:tag].is_a?(String)
    if @tag_query.present?
      @tag = Tag.find_by(name: @tag_query.downcase)
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
    # shelf id => shelf_book id, so the dropdown can link a saved list's entry to its remove route
    @shelf_book_ids = current_user ? ShelfBook.where(shelf: @user_shelves, book: @book).pluck(:shelf_id, :id).to_h : {}
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
    destroy_book_with_audit!(@book)

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
