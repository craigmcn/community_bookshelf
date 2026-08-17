class BooksController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  before_action :set_book, only: %i[show edit update destroy]

  def index
    @books = policy_scope(Book).includes(:added_by)
    @tags = Tag.order(:name)

    if params[:tag].present?
      @tag = Tag.find_by(name: params[:tag].to_s.strip.downcase)
      @books = @tag ? @books.joins(:tags).where(tags: {id: @tag.id}) : @books.none
    end
  end

  def show
    authorize @book
    @user_reading = current_user&.readings&.find_by(book: @book)
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
    @book.destroy!
    redirect_to books_path, notice: "Book was successfully destroyed.", status: :see_other
  end

  private

  def set_book
    @book = Book.find(params.expect(:id))
  end

  def book_params
    params.expect(book: [:title, :author, :cover_url, :isbn, :page_count, :published_on, :open_library_key, :series_id, :series_position, :tag_list])
  end
end
