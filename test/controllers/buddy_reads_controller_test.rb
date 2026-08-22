require "test_helper"

class BuddyReadsControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get buddy_reads_url
    assert_redirected_to sign_in_path
  end

  test "member can invite another member to a buddy read" do
    sign_in_as users(:member)
    post buddy_reads_url, params: {buddy_read: {book_id: books(:one).id, partner_id: users(:moderator).id}}

    buddy_read = BuddyRead.last
    assert_redirected_to buddy_read_url(buddy_read)
    assert_equal users(:member), buddy_read.initiator
    assert_equal users(:moderator), buddy_read.partner
    assert buddy_read.pending?
  end

  test "member cannot invite themselves" do
    sign_in_as users(:member)
    post buddy_reads_url, params: {buddy_read: {book_id: books(:one).id, partner_id: users(:member).id}}

    assert_response :unprocessable_content
    assert_nil BuddyRead.last
  end

  test "index only shows the current user's buddy reads" do
    mine = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    BuddyRead.create!(book: books(:two), initiator: users(:moderator), partner: users(:admin))

    sign_in_as users(:member)
    get buddy_reads_url

    assert_response :success
    assert_includes @response.body, mine.book.title
  end

  test "a third party cannot view someone else's buddy read" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    sign_in_as users(:admin)

    get buddy_read_url(buddy_read)
    assert_redirected_to root_path
  end

  test "partner can accept an invite" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    sign_in_as users(:moderator)

    patch buddy_read_url(buddy_read), params: {status: "accepted"}

    assert buddy_read.reload.accepted?
  end

  test "initiator cannot accept their own invite" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    sign_in_as users(:member)

    patch buddy_read_url(buddy_read), params: {status: "accepted"}

    assert buddy_read.reload.pending?
  end

  test "either participant can cancel" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    sign_in_as users(:member)

    patch buddy_read_url(buddy_read), params: {status: "cancelled"}

    assert buddy_read.reload.cancelled?
  end
end
