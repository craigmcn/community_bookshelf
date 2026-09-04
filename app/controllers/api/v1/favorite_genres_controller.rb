class Api::V1::FavoriteGenresController < Api::V1::BaseController
  before_action -> { require_scope!("read:favorite_genres") }, only: %i[index]
  before_action -> { require_scope!("write:favorite_genres") }, only: %i[create destroy]

  # No policy class: inherently scoped to current_user, same pattern as
  # ReadingChallenge/Shelf.
  def index
    @favorite_genres = current_user.favorite_genres.includes(:tag).order("tags.name")
  end

  # Operates directly on the FavoriteGenre join model (tag_id), not through
  # User#favorite_genre_list's comma-separated string parsing — that's a
  # form-layer convenience an API client shouldn't have to replicate. A
  # client browses existing tags via GET /api/v1/tags first, or falls back
  # to whatever genre tags already exist from books.
  #
  # Idempotent like ShelfBooksController#create — favoriting a genre twice
  # isn't a meaningful error case, unlike Follow.
  def create
    tag = Tag.find(params.expect(:tag_id))
    unless tag.genre?
      return render json: {errors: ["Tag must be a genre tag"]}, status: :unprocessable_content
    end

    begin
      @favorite_genre = current_user.favorite_genres.find_or_create_by(tag: tag)
    rescue ActiveRecord::RecordNotUnique
      # find_by! rather than find_by — a concurrent delete in the narrow
      # window between the rescue and this lookup should surface as the
      # same clean 404 Api::V1::BaseController already renders for
      # ActiveRecord::RecordNotFound, not an unhandled nil downstream.
      @favorite_genre = current_user.favorite_genres.find_by!(tag: tag)
    end
    render :show, status: :created
  end

  def destroy
    favorite_genre = current_user.favorite_genres.find(params.expect(:id))
    favorite_genre.destroy!
    head :no_content
  end
end
