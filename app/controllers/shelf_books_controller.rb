class ShelfBooksController < ApplicationController
  before_action :set_shelf

  # Adding/removing a book to/from a shelf is a management action on the
  # shelf itself, so it's authorized against the shelf (owner-only) rather
  # than a separate ShelfBookPolicy.
  def create
    authorize @shelf, :update?
    @book = Book.find(params.expect(:book_id))
    begin
      @shelf.shelf_books.find_or_create_by(book: @book)
    rescue ActiveRecord::RecordNotUnique
      # Already on the shelf (race with a concurrent add) — nothing to do.
    end
    redirect_back_or_to @shelf, notice: "Added \"#{@book.title}\" to #{@shelf.name}."
  end

  def destroy
    authorize @shelf, :update?
    shelf_book = @shelf.shelf_books.find(params.expect(:id))
    shelf_book.destroy
    redirect_back_or_to @shelf, notice: "Removed \"#{shelf_book.book.title}\" from #{@shelf.name}.", status: :see_other
  end

  private

  def set_shelf
    @shelf = current_user.shelves.find(params.expect(:shelf_id))
  end
end
