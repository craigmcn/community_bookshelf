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
end
