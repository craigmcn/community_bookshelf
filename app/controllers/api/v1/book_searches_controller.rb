class Api::V1::BookSearchesController < Api::V1::BaseController
  before_action -> { require_scope!("read:books") }

  def show
    render json: {results: OpenLibraryService.search(search_query)}
  end
end
