class Api::V1::Admin::DashboardsController < Api::V1::Admin::BaseController
  before_action :require_admin

  def show
    @total_users = User.excluding_deleted_placeholder.count
    @total_books = Book.count
    @total_readings = Reading.count
    @popular_books = Book.most_read
  end
end
