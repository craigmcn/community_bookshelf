require "test_helper"

class Api::V1::BuddyReadMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @moderator = users(:moderator)
    @admin = users(:admin)
    @buddy_read = BuddyRead.create!(book: books(:one), initiator: @member, partner: @moderator)
  end

  test "no token is rejected" do
    post api_v1_buddy_read_messages_url(@buddy_read), params: {buddy_read_message: {body: "Hi!"}}
    assert_response :unauthorized
  end

  test "participant can post a message" do
    assert_difference "@buddy_read.messages.count" do
      post api_v1_buddy_read_messages_url(@buddy_read), params: {buddy_read_message: {body: "Excited to start!"}}, headers: auth_headers(@member)
    end
    assert_response :created
    assert_equal "Excited to start!", JSON.parse(response.body)["body"]
  end

  test "a third party cannot post a message" do
    assert_no_difference "@buddy_read.messages.count" do
      post api_v1_buddy_read_messages_url(@buddy_read), params: {buddy_read_message: {body: "Hi!"}}, headers: auth_headers(@admin)
    end
    assert_response :forbidden
  end

  test "a participant cannot post a message after the buddy read is declined" do
    @buddy_read.update!(status: "declined")

    assert_no_difference "@buddy_read.messages.count" do
      post api_v1_buddy_read_messages_url(@buddy_read), params: {buddy_read_message: {body: "Still there?"}}, headers: auth_headers(@member)
    end
    assert_response :forbidden
  end

  test "a token without write:buddy_reads cannot post" do
    post api_v1_buddy_read_messages_url(@buddy_read), params: {buddy_read_message: {body: "Hi!"}}, headers: auth_headers(@member, scopes: ["read:buddy_reads"])
    assert_response :forbidden
  end
end
