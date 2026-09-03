class Api::V1::StatsController < Api::V1::BaseController
  before_action -> { require_scope!("read:stats") }

  # No policy class: inherently scoped to current_user, same pattern as the
  # HTML StatsController.
  def show
    @genre_breakdown = current_user.genre_breakdown
    @books_finished_by_month = current_user.books_finished_by_month
    @pages_read_by_month = current_user.pages_read_by_month
  end
end
