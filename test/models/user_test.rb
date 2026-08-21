require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with email and password" do
    assert User.new(email: "new@example.com", password: User::DEFAULT_PASSWORD).valid?
  end

  test "invalid without email" do
    assert_not User.new(password: User::DEFAULT_PASSWORD).valid?
  end

  test "invalid with duplicate email" do
    assert_not User.new(email: users(:member).email, password: User::DEFAULT_PASSWORD).valid?
  end

  test "role enum" do
    assert users(:member).member?
    assert users(:admin).admin?
  end

  test "new user is assigned member role on create" do
    user = User.create!(email: "newuser@example.com", password: User::DEFAULT_PASSWORD)
    assert user.member?
    assert user.roles.exists?(name: "member")
  end

  test "display_name falls back to email when name is blank" do
    user = users(:member)
    assert_nil user.name
    assert_equal user.email, user.display_name
  end

  test "display_name prefers the name when set" do
    user = users(:member)
    user.update!(name: "Sam Reader")
    assert_equal "Sam Reader", user.display_name
  end

  test "invalid with a name over 100 characters" do
    user = User.new(email: "long@example.com", password: User::DEFAULT_PASSWORD, name: "a" * 101)
    assert_not user.valid?
  end

  test "invalid with a bio over 500 characters" do
    user = User.new(email: "longbio@example.com", password: User::DEFAULT_PASSWORD, bio: "a" * 501)
    assert_not user.valid?
  end

  test "new user gets an email confirmation token and a confirmation email" do
    assert_enqueued_emails 1 do
      user = User.create!(email: "newuser@example.com", password: User::DEFAULT_PASSWORD)
      assert_not user.email_confirmed?
      assert user.reload.email_confirmation_token.present?
    end
  end

  test "creating the placeholder does not send a confirmation email" do
    assert_no_enqueued_emails do
      User.deleted_placeholder
    end
  end

  test "confirm_email! confirms with a matching token and clears it" do
    user = User.create!(email: "toconfirm@example.com", password: User::DEFAULT_PASSWORD)
    token = user.email_confirmation_token

    assert user.confirm_email!(token)
    assert user.email_confirmed?
    assert_nil user.email_confirmation_token
  end

  test "confirm_email! rejects a wrong or blank token" do
    user = User.create!(email: "wrongtoken@example.com", password: User::DEFAULT_PASSWORD)

    assert_not user.confirm_email!("not-the-real-token")
    assert_not user.confirm_email!(nil)
    assert_not user.email_confirmed?
  end

  test "deleted_placeholder is memoized across calls" do
    first = User.deleted_placeholder
    second = User.deleted_placeholder
    assert_equal first.id, second.id
    assert_equal "Deleted user", first.display_name
  end

  test "delete_account! reassigns the user's books to the placeholder and destroys the user" do
    user = users(:member)
    book = books(:one)
    book.update!(added_by: user)
    User.deleted_placeholder # pre-create so the assertion below isn't masked by its own +1

    assert_difference "User.count", -1 do
      user.delete_account!
    end

    assert_equal User.deleted_placeholder, book.reload.added_by
  end

  test "invalid with an avatar over the size limit" do
    user = users(:member)
    user.avatar.attach(
      io: StringIO.new("a" * (User::MAX_AVATAR_BYTES + 1)),
      filename: "big.png",
      content_type: "image/png"
    )

    assert_not user.valid?
    assert_includes user.errors[:avatar], "is too large (maximum is 5MB)"
  end

  test "invalid with an unsupported avatar content type" do
    user = users(:member)
    user.avatar.attach(io: StringIO.new("not really a gif"), filename: "avatar.gif", content_type: "image/gif")

    assert_not user.valid?
    assert_includes user.errors[:avatar], "must be a PNG, JPEG, or WEBP image"
  end

  test "valid with a supported, appropriately-sized avatar" do
    user = users(:member)
    user.avatar.attach(io: StringIO.new("small png content"), filename: "avatar.png", content_type: "image/png")

    assert user.valid?
  end

  test "delete_account! destroys the user's readings and shelves" do
    user = users(:member)
    reading = readings(:one)
    shelf = Shelf.create!(user: user, name: "Beach Reads")

    user.delete_account!

    assert_not Reading.unscoped.exists?(reading.id)
    assert_not Shelf.exists?(shelf.id)
  end
end
