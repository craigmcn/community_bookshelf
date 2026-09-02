require "test_helper"

class Api::V1::ShelvesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shelf = shelves(:one)
    @other_shelf = shelves(:two)
  end

  test "no token is rejected" do
    get api_v1_shelves_url
    assert_response :unauthorized
  end

  test "valid token lists only the token owner's shelves" do
    get api_v1_shelves_url, headers: auth_headers(users(:member))
    assert_response :success
    names = JSON.parse(response.body)["shelves"].pluck("name")
    assert_equal [@shelf.name], names.uniq
  end

  test "valid token can show its own shelf" do
    get api_v1_shelf_url(@shelf), headers: auth_headers(users(:member))
    assert_response :success
    assert_equal @shelf.name, JSON.parse(response.body)["name"]
  end

  test "cannot show another user's shelf" do
    get api_v1_shelf_url(@other_shelf), headers: auth_headers(users(:member))
    assert_response :not_found
  end

  test "member can create a shelf" do
    assert_difference "Shelf.count" do
      post api_v1_shelves_url, params: {shelf: {name: "To Read Next"}}, headers: auth_headers(users(:member))
    end
    assert_response :created
    assert_equal users(:member).id, JSON.parse(response.body)["user_id"]
  end

  test "create with invalid params returns 422 with errors" do
    assert_no_difference "Shelf.count" do
      post api_v1_shelves_url, params: {shelf: {name: ""}}, headers: auth_headers(users(:member))
    end
    assert_response :unprocessable_content
    assert JSON.parse(response.body)["errors"].present?
  end

  test "member can update their own shelf" do
    patch api_v1_shelf_url(@shelf), params: {shelf: {name: "Renamed"}}, headers: auth_headers(users(:member))
    assert_response :success
    assert_equal "Renamed", @shelf.reload.name
  end

  test "member cannot update another user's shelf" do
    patch api_v1_shelf_url(@other_shelf), params: {shelf: {name: "Renamed"}}, headers: auth_headers(users(:member))
    assert_response :not_found
    assert_not_equal "Renamed", @other_shelf.reload.name
  end

  test "member can destroy their own shelf" do
    assert_difference "Shelf.count", -1 do
      delete api_v1_shelf_url(@shelf), headers: auth_headers(users(:member))
    end
    assert_response :no_content
  end

  test "a read:shelves-only token can list shelves" do
    get api_v1_shelves_url, headers: auth_headers(users(:member), scopes: ["read:shelves"])
    assert_response :success
  end

  test "a read:shelves-only token cannot create a shelf" do
    assert_no_difference "Shelf.count" do
      post api_v1_shelves_url, params: {shelf: {name: "New"}}, headers: auth_headers(users(:member), scopes: ["read:shelves"])
    end
    assert_response :forbidden
  end

  test "a write:shelves-only token cannot list shelves" do
    get api_v1_shelves_url, headers: auth_headers(users(:member), scopes: ["write:shelves"])
    assert_response :forbidden
  end
end
