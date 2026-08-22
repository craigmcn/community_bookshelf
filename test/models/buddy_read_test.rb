require "test_helper"

class BuddyReadTest < ActiveSupport::TestCase
  test "valid with distinct initiator and partner" do
    buddy_read = BuddyRead.new(book: books(:one), initiator: users(:member), partner: users(:moderator))
    assert buddy_read.valid?
  end

  test "invalid inviting yourself" do
    buddy_read = BuddyRead.new(book: books(:one), initiator: users(:member), partner: users(:member))
    assert_not buddy_read.valid?
  end

  test "defaults to pending status" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    assert buddy_read.pending?
  end

  test "participant? is true for either side" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    assert buddy_read.participant?(users(:member))
    assert buddy_read.participant?(users(:moderator))
    assert_not buddy_read.participant?(users(:admin))
  end

  test "other_participant returns the other side" do
    buddy_read = BuddyRead.create!(book: books(:one), initiator: users(:member), partner: users(:moderator))
    assert_equal users(:moderator), buddy_read.other_participant(users(:member))
    assert_equal users(:member), buddy_read.other_participant(users(:moderator))
  end

  test "messageable? is true while pending, accepted, or completed" do
    buddy_read = BuddyRead.new(status: "pending")
    assert buddy_read.messageable?
    buddy_read.status = "accepted"
    assert buddy_read.messageable?
    buddy_read.status = "completed"
    assert buddy_read.messageable?
  end

  test "messageable? is false once declined or cancelled" do
    buddy_read = BuddyRead.new(status: "declined")
    assert_not buddy_read.messageable?
    buddy_read.status = "cancelled"
    assert_not buddy_read.messageable?
  end
end
