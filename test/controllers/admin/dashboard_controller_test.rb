require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get admin_root_url
    assert_redirected_to sign_in_path
  end

  test "member gets forbidden" do
    sign_in_as users(:member)
    get admin_root_url
    assert_response :forbidden
  end

  test "admin can access the dashboard" do
    sign_in_as users(:admin)
    get admin_root_url
    assert_response :success
  end

  test "admin dashboard renders trend charts" do
    sign_in_as users(:admin)
    get admin_root_url
    assert_response :success
    assert_select "h3", text: "Trends"
  end

  # The fixtures give only one book readings, and Bullet needs two to flag a per-book count (#256).
  test "popular books show reading counts without a query per book" do
    Reading.create!(user: users(:member), book: books(:two), status: :want_to_read)
    Reading.create!(user: users(:moderator), book: books(:two), status: :reading)

    sign_in_as users(:admin)
    get admin_root_url

    assert_response :success
    assert_select "td span.badge", text: "2"
    assert_select "td span.badge", text: "1"
  end

  test "total user count excludes the deleted-user placeholder" do
    starting_count = User.excluding_deleted_placeholder.count
    User.deleted_placeholder

    sign_in_as users(:admin)
    get admin_root_url

    assert_response :success
    assert_select ".display-4.text-primary", text: starting_count.to_s
  end
end
