require "test_helper"

class Api::V1::BuddyReadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @moderator = users(:moderator)
    @admin = users(:admin)
  end

  test "no token is rejected" do
    get api_v1_buddy_reads_url
    assert_response :unauthorized
  end

  test "member can invite another member to a buddy read" do
    assert_difference "BuddyRead.count" do
      post api_v1_buddy_reads_url, params: {buddy_read: {book_id: books(:one).id, partner_id: @moderator.id}}, headers: auth_headers(@member)
    end
    assert_response :created

    buddy_read = BuddyRead.last
    assert_equal @member, buddy_read.initiator
    assert_equal @moderator, buddy_read.partner
    assert buddy_read.pending?
    assert_equal "pending", JSON.parse(response.body)["status"]
  end

  test "member cannot invite themselves" do
    assert_no_difference "BuddyRead.count" do
      post api_v1_buddy_reads_url, params: {buddy_read: {book_id: books(:one).id, partner_id: @member.id}}, headers: auth_headers(@member)
    end
    assert_response :unprocessable_content
  end

  test "index only shows the token owner's buddy reads" do
    mine = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)
    BuddyRead.create!(book: books(:two), initiator: @moderator, partner: @admin)

    get api_v1_buddy_reads_url, headers: auth_headers(@member)
    assert_response :success
    ids = JSON.parse(response.body)["buddy_reads"].pluck("id")
    assert_equal [mine.id], ids
  end

  test "index nests book and both participants" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)

    get api_v1_buddy_reads_url, headers: auth_headers(@member)
    json_row = JSON.parse(response.body)["buddy_reads"].find { |r| r["id"] == buddy_read.id }
    assert_equal books(:one).title, json_row["book"]["title"]
    assert_equal @member.display_name, json_row["initiator"]["display_name"]
    assert_equal @moderator.display_name, json_row["partner"]["display_name"]
  end

  test "a third party cannot view someone else's buddy read" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)

    get api_v1_buddy_read_url(buddy_read), headers: auth_headers(@admin)
    assert_response :forbidden
  end

  test "partner can accept an invite" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)

    patch api_v1_buddy_read_url(buddy_read), params: {status: "accepted"}, headers: auth_headers(@moderator)
    assert_response :success
    assert buddy_read.reload.accepted?
  end

  test "initiator cannot accept their own invite and gets a 422 explaining why" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)

    patch api_v1_buddy_read_url(buddy_read), params: {status: "accepted"}, headers: auth_headers(@member)
    assert_response :unprocessable_content
    assert JSON.parse(response.body)["errors"].present?
    assert buddy_read.reload.pending?
  end

  test "either participant can cancel" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)

    patch api_v1_buddy_read_url(buddy_read), params: {status: "cancelled"}, headers: auth_headers(@member)
    assert_response :success
    assert buddy_read.reload.cancelled?
  end

  test "cannot complete a buddy read that hasn't been accepted" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)

    patch api_v1_buddy_read_url(buddy_read), params: {status: "completed"}, headers: auth_headers(@member)
    assert_response :unprocessable_content
    assert buddy_read.reload.pending?
  end

  test "an unrecognized status returns a 422" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)

    patch api_v1_buddy_read_url(buddy_read), params: {status: "bogus"}, headers: auth_headers(@member)
    assert_response :unprocessable_content
  end

  test "a token without write:buddy_reads cannot create one" do
    assert_no_difference "BuddyRead.count" do
      post api_v1_buddy_reads_url, params: {buddy_read: {book_id: books(:one).id, partner_id: @moderator.id}}, headers: auth_headers(@member, scopes: ["read:buddy_reads"])
    end
    assert_response :forbidden
  end
end
