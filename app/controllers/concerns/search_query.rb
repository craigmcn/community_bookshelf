# ?q= can arrive as an array or hash (q[]=x, q[k]=x); treating that as no search,
# rather than calling String methods on it, keeps a crafted link from raising a 500 (#242).
module SearchQuery
  extend ActiveSupport::Concern

  private

  def search_query
    params[:q].strip.presence if params[:q].is_a?(String)
  end
end
