class Api::V1::BooksController < Api::V1::BaseController
  before_action -> { require_scope!("read:books") }, only: %i[index show]
  before_action -> { require_scope!("write:books") }, only: %i[create update destroy]
  before_action :set_book, only: %i[show update destroy]

  def index
    @books = policy_scope(Book)

    if params[:q].present?
      query = "%#{params[:q].strip}%"
      @books = @books.where("books.title ILIKE :q OR books.author ILIKE :q", q: query)
    end

    @books = @books.order(:title)
    @pagy, @books = pagy(@books)
    fresh_when @books
  end

  def show
    authorize @book
    fresh_when @book
  end

  def create
    @book = Book.new(book_params.merge(added_by: current_user))
    authorize @book

    detail = OpenLibraryService.work_detail(@book.open_library_key)
    @book.description = detail[:description] if detail[:description].present?
    @book.subjects = detail[:subjects] if detail[:subjects].present?

    if @book.save
      render :show, status: :created
    else
      render json: {errors: @book.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @book
    if @book.update(book_params)
      render :show
    else
      render json: {errors: @book.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    authorize @book
    @book.destroy!
    head :no_content
  end

  private

  def set_book
    @book = Book.find(params.expect(:id))
  end

  def book_params
    params.expect(book: [:title, :author, :cover_url, :isbn, :page_count, :published_on, :open_library_key, :series_id, :series_position, :tag_list, :mood_list, :pace_list])
  end
end
