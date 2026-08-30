require "test_helper"

class LayoutAccessibilityTest < ActionDispatch::IntegrationTest
  test "html has a lang attribute" do
    get books_url
    assert_select "html[lang=en]"
  end

  test "has a skip-to-content link targeting the main landmark" do
    get books_url
    assert_select "a.visually-hidden-focusable[href='#main-content']", text: "Skip to content"
    assert_select "main#main-content"
  end

  test "navbar toggler has an accessible name and reflects the collapse target" do
    get books_url
    assert_select "button.navbar-toggler[aria-controls=navbarMain][aria-expanded=false][aria-label=?]", "Toggle navigation"
  end

  test "notification bell always has an accessible name" do
    sign_in_as users(:member)
    get books_url
    assert_select "a[href=?][aria-label=?]", notifications_path, "Notifications"
  end

  test "notification bell announces the unread count when there are unread notifications" do
    member = users(:member)
    Follow.create!(follower: users(:admin), followed: member) # after_create notifies the followed user

    sign_in_as member
    get books_url

    assert_select "a[href=?][aria-label=?]", notifications_path, "Notifications (1 unread)"
  end
end
