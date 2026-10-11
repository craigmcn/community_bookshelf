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
    assert_select "a.dropdown-toggle[aria-label=?]", "Notifications"
  end

  test "notification bell announces the unread count when there are unread notifications" do
    member = users(:member)
    Follow.create!(follower: users(:admin), followed: member) # after_create notifies the followed user

    sign_in_as member
    get books_url

    assert_select "a.dropdown-toggle[aria-label=?]", "Notifications (1 unread)"
  end

  test "notification bell dropdown previews the most recent notifications and a mark-all-read action" do
    member = users(:member)
    Follow.create!(follower: users(:admin), followed: member) # after_create notifies the followed user

    sign_in_as member
    get books_url

    assert_select "form[action=?] button.dropdown-item", mark_all_read_notifications_path, text: "Mark all as read"
    assert_select "form[action=?] button.dropdown-item", notification_path(member.notifications.last), text: /started following you/
    assert_select "a.dropdown-item[href=?]", notifications_path, text: "View all notifications"
  end

  test "notification bell dropdown shows an empty state when there are no notifications" do
    sign_in_as users(:member)
    get books_url

    assert_select "form[action=?]", mark_all_read_notifications_path, count: 0
    assert_select "span.dropdown-item-text", text: "No notifications yet."
  end

  test "notification bell dropdown still previews read notifications but has no mark-all-read action" do
    member = users(:member)
    Follow.create!(follower: users(:admin), followed: member)
    member.notifications.update_all(read_at: Time.current)

    sign_in_as member
    get books_url

    assert_select "form[action=?] button.dropdown-item", notification_path(member.notifications.last), text: /started following you/
    assert_select "form[action=?]", mark_all_read_notifications_path, count: 0
  end
end
