class Api::V1::TagsController < Api::V1::BaseController
  before_action -> { require_scope!("read:tags") }

  # No policy class: tags aren't ownership-scoped, same reasoning as the
  # public parts of BooksController.
  def index
    @tags = Tag.order(:name)
    @tags = @tags.where(category: params[:category]) if params[:category].present? && Tag.categories.key?(params[:category])
  end
end
