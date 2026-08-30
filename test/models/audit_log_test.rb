require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "requires an action" do
    audit_log = AuditLog.new(actor: users(:admin), subject: books(:one))
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:action], "can't be blank"
  end

  test "requires an actor and a subject" do
    audit_log = AuditLog.new(action: "destroy_book")
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:actor], "must exist"
    assert_includes audit_log.errors[:subject], "must exist"
  end

  test "deleting a user reassigns their audit logs to the deleted-user placeholder" do
    moderator = users(:moderator)
    audit_log = AuditLog.create!(actor: moderator, action: "destroy_book", subject: books(:one))

    moderator.delete_account!

    assert_equal User.deleted_placeholder, audit_log.reload.actor
  end
end
