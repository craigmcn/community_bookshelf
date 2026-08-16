require "test_helper"

class SeriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @series = series(:one)
  end

  # Public access
  test "anyone can view series index" do
    get series_index_url
    assert_response :success
  end

  test "anyone can view a series" do
    get series_url(@series)
    assert_response :success
  end

  # Auth wall
  test "guest is redirected to sign in for new" do
    get new_series_url
    assert_redirected_to sign_in_path
  end

  test "guest is redirected to sign in for create" do
    post series_index_url, params: {series: {name: "New Series"}}
    assert_redirected_to sign_in_path
  end

  # Member permissions
  test "member cannot create a series" do
    sign_in_as users(:member)
    assert_no_difference "Series.count" do
      post series_index_url, params: {series: {name: "New Series"}}
    end
  end

  test "member cannot update a series" do
    sign_in_as users(:member)
    patch series_url(@series), params: {series: {name: "Changed"}}
    assert_response :redirect
    assert_not_equal "Changed", @series.reload.name
  end

  test "member cannot destroy a series" do
    sign_in_as users(:member)
    assert_no_difference "Series.count" do
      delete series_url(@series)
    end
  end

  # Moderator permissions
  test "moderator can view the new series form" do
    sign_in_as users(:moderator)
    get new_series_url
    assert_response :success
  end

  test "moderator can view the edit series form" do
    sign_in_as users(:moderator)
    get edit_series_url(@series)
    assert_response :success
  end

  test "moderator can create a series" do
    sign_in_as users(:moderator)
    assert_difference "Series.count" do
      post series_index_url, params: {series: {name: "New Series"}}
    end
    assert_redirected_to series_url(Series.last)
  end

  test "moderator can update a series" do
    sign_in_as users(:moderator)
    patch series_url(@series), params: {series: {name: "Updated"}}
    assert_redirected_to series_url(@series)
    assert_equal "Updated", @series.reload.name
  end

  test "moderator can destroy a series" do
    sign_in_as users(:moderator)
    assert_difference "Series.count", -1 do
      delete series_url(@series)
    end
    assert_redirected_to series_index_url
  end
end
