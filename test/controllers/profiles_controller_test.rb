require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get user_url(users(:member))
    assert_redirected_to sign_in_path
  end

  test "signed-in member can view another member's profile" do
    sign_in_as users(:member)
    get user_url(users(:moderator))
    assert_response :success
  end

  test "profile shows only public reviews" do
    users(:member).update!(favorite_genre_list: "fantasy")

    sign_in_as users(:moderator)
    get user_url(users(:member))

    assert_response :success
    assert_select "a.badge", text: "fantasy"
  end

  test "deleted placeholder account has no profile page" do
    placeholder = User.deleted_placeholder
    sign_in_as users(:member)

    get user_url(placeholder)
    assert_response :not_found
  end
end
