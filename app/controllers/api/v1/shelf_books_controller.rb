class Api::V1::ShelfBooksController < Api::V1::BaseController
  before_action -> { require_scope!("write:shelves") }
  before_action :set_shelf

  # Adding a book to a shelf is a management action on the shelf itself, so
  # it's authorized against the shelf (owner-only) rather than a separate
  # ShelfBookPolicy — same reasoning as the HTML ShelfBooksController.
  def create
    authorize @shelf, :update?
    @book = Book.find(params.expect(:book_id))
    begin
      @shelf_book = @shelf.shelf_books.find_or_create_by(book: @book)
    rescue ActiveRecord::RecordNotUnique
      # find_by! rather than find_by — a concurrent delete in the narrow
      # window between the rescue and this lookup should surface as the
      # same clean 404 Api::V1::BaseController already renders for
      # ActiveRecord::RecordNotFound, not an unhandled nil downstream.
      @shelf_book = @shelf.shelf_books.find_by!(book: @book)
    end
    render "api/v1/shelves/show", status: :created
  end

  def destroy
    authorize @shelf, :update?
    shelf_book = @shelf.shelf_books.find(params.expect(:id))
    shelf_book.destroy!
    head :no_content
  end

  private

  def set_shelf
    @shelf = current_user.shelves.find(params.expect(:shelf_id))
  end
end
