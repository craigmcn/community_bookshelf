require "test_helper"

class Admin::ReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading = readings(:one)
  end

  test "guest cannot soft-delete a reading" do
    delete admin_reading_url(@reading)
    assert_nil @reading.reload.deleted_at
  end

  test "member cannot soft-delete a reading" do
    sign_in_as users(:member)
    delete admin_reading_url(@reading)
    assert_response :forbidden
    assert_nil @reading.reload.deleted_at
  end

  test "moderator soft-deletes in place via Turbo Stream" do
    sign_in_as users(:moderator)
    assert_difference "AuditLog.count", 1 do
      delete admin_reading_url(@reading), as: :turbo_stream
    end

    assert_response :success
    assert_not_nil @reading.reload.deleted_at
    assert_select "turbo-stream[action=replace][target=?]", "reading_#{@reading.id}" do
      assert_select "template tr.opacity-50 .badge", text: "Deleted"
    end
  end

  test "moderator without Turbo falls back to the admin list" do
    sign_in_as users(:moderator)
    delete admin_reading_url(@reading)
    assert_redirected_to admin_readings_url
    assert_not_nil @reading.reload.deleted_at
  end

  test "moderator cannot soft-delete an already-deleted reading" do
    @reading.soft_delete
    sign_in_as users(:moderator)
    assert_no_difference "AuditLog.count" do
      delete admin_reading_url(@reading), as: :turbo_stream
    end
  end

  test "admin list posts deletes to the admin route" do
    sign_in_as users(:moderator)
    get admin_readings_url
    assert_select "form[action=?]", admin_reading_path(@reading)
  end
end
