class BookSearchController < ApplicationController
  def index
    query = params[:q].to_s.strip

    @results = if query.present?
      OpenLibraryService.search(query)
    end

    render layout: false
  end
end
