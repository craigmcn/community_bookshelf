class Admin::DashboardController < Admin::BaseController
  before_action :require_admin

  def index
    @total_users = User.count
    @total_books = Book.count
    @total_readings = Reading.count
    @popular_books = Book.joins(:readings)
      .group(:id)
      .select("books.*, COUNT(readings.id) AS readings_count")
      .order(readings_count: :desc)
      .limit(5)
  end
end
