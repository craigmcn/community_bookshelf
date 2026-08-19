require "test_helper"

class ShelvesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shelf = shelves(:one) # owned by member
  end

  test "guest is redirected to sign in" do
    get shelves_url
    assert_redirected_to sign_in_path
  end

  test "member can view their own lists" do
    sign_in_as users(:member)
    get shelves_url
    assert_response :success
  end

  test "member can create a list" do
    sign_in_as users(:member)
    assert_difference "Shelf.count" do
      post shelves_url, params: {shelf: {name: "2026 TBR"}}
    end
    assert_redirected_to shelf_url(Shelf.last)
  end

  test "member cannot create a duplicate-named list" do
    sign_in_as users(:member)
    assert_no_difference "Shelf.count" do
      post shelves_url, params: {shelf: {name: @shelf.name}}
    end
    assert_response :unprocessable_content
  end

  test "member can view their own shelf" do
    sign_in_as users(:member)
    get shelf_url(@shelf)
    assert_response :success
  end

  test "member cannot view another user's shelf" do
    sign_in_as users(:member)
    get shelf_url(shelves(:two))
    assert_response :not_found
  end

  test "member can rename their own shelf" do
    sign_in_as users(:member)
    patch shelf_url(@shelf), params: {shelf: {name: "Renamed"}}
    assert_redirected_to shelf_url(@shelf)
    assert_equal "Renamed", @shelf.reload.name
  end

  test "member cannot rename another user's shelf" do
    sign_in_as users(:member)
    patch shelf_url(shelves(:two)), params: {shelf: {name: "Renamed"}}
    assert_response :not_found
  end

  test "member can destroy their own shelf" do
    sign_in_as users(:member)
    assert_difference "Shelf.count", -1 do
      delete shelf_url(@shelf)
    end
    assert_redirected_to shelves_url
  end

  test "member cannot destroy another user's shelf" do
    sign_in_as users(:member)
    assert_no_difference "Shelf.count" do
      delete shelf_url(shelves(:two))
    end
    assert_response :not_found
  end

  test "moderator cannot view a member's shelf" do
    sign_in_as users(:moderator)
    get shelf_url(@shelf)
    assert_response :not_found
  end

  test "moderator cannot destroy a member's shelf" do
    sign_in_as users(:moderator)
    assert_no_difference "Shelf.count" do
      delete shelf_url(@shelf)
    end
    assert_response :not_found
  end

  test "admin cannot view a member's shelf" do
    sign_in_as users(:admin)
    get shelf_url(@shelf)
    assert_response :not_found
  end
end
