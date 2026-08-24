class StatsController < ApplicationController
  # No policy class: inherently scoped to current_user, the same pattern
  # ActivitiesController uses for /feed.
  def show
    @genre_breakdown = current_user.genre_breakdown
    @books_finished_by_month = current_user.books_finished_by_month
    @pages_read_by_month = current_user.pages_read_by_month
    @has_finished_readings = current_user.readings.finished.where.not(finished_on: nil).exists?
    @has_page_counted_finished_readings = current_user.readings.finished.joins(:book)
      .where.not(finished_on: nil).where.not(books: {page_count: nil}).exists?
  end
end
