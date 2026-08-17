class ShelvesController < ApplicationController
  before_action :set_shelf, only: %i[show edit update destroy]

  def index
    @shelves = current_user.shelves.order(:name)
  end

  def show
    authorize @shelf
    @shelf_books = @shelf.shelf_books.includes(:book).sort_by { |shelf_book| shelf_book.book.title }
  end

  def new
    @shelf = current_user.shelves.build
  end

  def edit
    authorize @shelf
  end

  def create
    @shelf = current_user.shelves.build(shelf_params)
    authorize @shelf

    if @shelf.save
      redirect_to @shelf, notice: "List was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @shelf
    if @shelf.update(shelf_params)
      redirect_to @shelf, notice: "List was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @shelf
    @shelf.destroy
    redirect_to shelves_path, notice: "List was removed.", status: :see_other
  end

  private

  # Scoped to current_user.shelves rather than a bare Shelf.find, so a
  # non-owner requesting another user's shelf id gets a 404 instead of ever
  # reaching the authorize call.
  def set_shelf
    @shelf = current_user.shelves.find(params.expect(:id))
  end

  def shelf_params
    params.expect(shelf: [:name])
  end
end
