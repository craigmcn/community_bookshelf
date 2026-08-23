class Admin::DashboardController < Admin::BaseController
  before_action :require_admin

  def index
    @total_users = User.excluding_deleted_placeholder.count
    @total_books = Book.count
    @total_readings = Reading.count
    @popular_books = Book.joins(:readings)
      .group(:id)
      .select("books.*, COUNT(readings.id) AS readings_count")
      .order(readings_count: :desc)
      .limit(5)

    @new_users_by_month = User.excluding_deleted_placeholder.group_by_month(:created_at, last: 12).count
    @books_added_by_month = Book.group_by_month(:created_at, last: 12).count
    @readings_logged_by_month = Reading.group_by_month(:created_at, last: 12).count
  end
end
