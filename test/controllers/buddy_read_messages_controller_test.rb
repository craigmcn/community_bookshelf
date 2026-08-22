require "test_helper"

class BuddyReadMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
  end

  test "participant can post a message" do
    sign_in_as users(:member)
    post buddy_read_messages_url(@buddy_read), params: {buddy_read_message: {body: "Excited to start!"}}

    assert_redirected_to buddy_read_url(@buddy_read)
    assert @buddy_read.messages.exists?(user: users(:member), body: "Excited to start!")
  end

  test "a third party cannot post a message" do
    sign_in_as users(:admin)
    post buddy_read_messages_url(@buddy_read), params: {buddy_read_message: {body: "Hi!"}}

    assert_not @buddy_read.messages.exists?(user: users(:admin))
  end
end
