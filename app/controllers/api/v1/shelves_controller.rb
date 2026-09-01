class Api::V1::ShelvesController < Api::V1::BaseController
  before_action -> { require_scope!("read:shelves") }, only: %i[index show]
  before_action -> { require_scope!("write:shelves") }, only: %i[create update destroy]
  before_action :set_shelf, only: %i[show update destroy]

  def index
    @shelves = policy_scope(Shelf).includes(:shelf_books).order(:name)
    @pagy, @shelves = pagy(@shelves)
  end

  def show
    authorize @shelf
  end

  def create
    @shelf = current_user.shelves.build(shelf_params)
    authorize @shelf

    if @shelf.save
      render :show, status: :created
    else
      render json: {errors: @shelf.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @shelf
    if @shelf.update(shelf_params)
      render :show
    else
      render json: {errors: @shelf.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    authorize @shelf
    @shelf.destroy
    head :no_content
  end

  private

  # Scoped to current_user.shelves rather than a bare Shelf.find, matching
  # the HTML ShelvesController — a non-owner requesting another user's shelf
  # id gets a 404 instead of ever reaching the authorize call.
  def set_shelf
    @shelf = current_user.shelves.find(params.expect(:id))
  end

  def shelf_params
    params.expect(shelf: [:name])
  end
end
