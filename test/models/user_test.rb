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

  test "new user is assigned an api_token on create" do
    user = User.create!(email: "newuser@example.com", password: User::DEFAULT_PASSWORD)
    assert user.api_token.present?
  end

  test "regenerate_api_token changes the token" do
    user = User.create!(email: "newuser@example.com", password: User::DEFAULT_PASSWORD)
    original_token = user.api_token
    user.regenerate_api_token
    assert_not_equal original_token, user.api_token
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

  test "favorite_genre_list assigns genre tags, creating them as needed" do
    user = users(:member)
    user.update!(favorite_genre_list: "Fantasy, sci-fi")

    assert_equal ["fantasy", "sci-fi"], user.favorite_genre_tags.order(:name).pluck(:name)
    assert user.favorite_genre_tags.all? { |tag| tag.genre? }
  end

  test "favorite_genre_list removes tags no longer listed and reuses an existing tag" do
    user = users(:member)
    user.update!(favorite_genre_list: "fantasy, mystery")
    user.update!(favorite_genre_list: "fantasy")

    assert_equal ["fantasy"], user.favorite_genre_tags.pluck(:name)
  end

  test "favorite_genre_list is untouched when omitted from an update" do
    user = users(:member)
    user.update!(favorite_genre_list: "fantasy")

    user.update!(name: "Sam Reader")

    assert_equal ["fantasy"], user.reload.favorite_genre_tags.pluck(:name)
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

  test "delete_account! reassigns clubs the user created to the placeholder" do
    user = users(:member)
    club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: user)
    User.deleted_placeholder # pre-create so the assertion below isn't masked by its own +1

    assert_difference "User.count", -1 do
      user.delete_account!
    end

    assert_equal User.deleted_placeholder, club.reload.created_by
  end

  test "delete_account! destroys the user's own club posts without a foreign key error" do
    other_member = User.create!(email: "creator@example.com", password: User::DEFAULT_PASSWORD)
    club = Club.create!(name: "Sci-Fi Society", book: books(:one), created_by: other_member)
    user = users(:member)
    ClubPost.create!(club: club, user: user, body: "Excited to start!")

    assert_difference "ClubPost.count", -1 do
      user.delete_account!
    end
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

  test "delete_account! destroys a soft-deleted reading too, instead of failing on its FK" do
    user = users(:member)
    reading = readings(:one)
    reading.soft_delete
    assert_not_nil reading.deleted_at

    user.delete_account!

    assert_not Reading.unscoped.exists?(reading.id)
  end

  test "delete_account! raises for the sole admin instead of leaving the app with none" do
    admin = users(:admin)
    assert admin.sole_admin?

    assert_raises(User::SoleAdminError) { admin.delete_account! }
    assert User.exists?(admin.id)
  end

  test "delete_account! succeeds for an admin when another admin exists" do
    admin = users(:admin)
    other_admin = User.create!(email: "otheradmin@example.com", password: User::DEFAULT_PASSWORD)
    other_admin.roles = [roles(:admin)]
    assert_not admin.sole_admin?
    User.deleted_placeholder # pre-create so the assertion below isn't masked by its own +1

    assert_difference "User.count", -1 do
      admin.delete_account!
    end
  end

  test "sole_admin? is false for a non-admin" do
    assert_not users(:member).sole_admin?
    assert_not users(:moderator).sole_admin?
  end

  test "deleted_placeholder recovers from a concurrent create losing the uniqueness validation race" do
    User.where(email: User::DELETED_PLACEHOLDER_EMAIL).destroy_all
    # Simulates the interleaving where another process's create already
    # committed by the time this one's uniqueness validation runs.
    User.create!(email: User::DELETED_PLACEHOLDER_EMAIL, name: "Deleted user", password: SecureRandom.hex(32), skip_confirmation_email: true)

    placeholder = User.deleted_placeholder

    assert_equal "Deleted user", placeholder.display_name
  end

  test "email_confirmation_on_cooldown? is true immediately after sending, false once the cooldown elapses" do
    user = User.create!(email: "cooldown@example.com", password: User::DEFAULT_PASSWORD)
    assert user.email_confirmation_on_cooldown?

    user.update_column(:email_confirmation_sent_at, (User::RESEND_COOLDOWN + 1.second).ago)
    assert_not user.email_confirmation_on_cooldown?
  end

  test "current_streak is zero with no finished books" do
    assert_equal 0, users(:member).current_streak
  end

  test "current_streak counts consecutive finishes within the gap window" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: 2.days.ago.to_date)
    Reading.create!(user: member, book: books(:two), status: :finished, finished_on: 20.days.ago.to_date)

    assert_equal 2, member.reload.current_streak
  end

  test "current_streak breaks on a gap larger than STREAK_GAP_DAYS" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: 2.days.ago.to_date)
    Reading.create!(user: member, book: books(:two), status: :finished, finished_on: 40.days.ago.to_date)

    assert_equal 1, member.reload.current_streak
  end

  test "current_streak is zero when the most recent finish is outside the gap window" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: 40.days.ago.to_date)

    assert_equal 0, member.reload.current_streak
  end

  test "award_badges! awards a books_finished badge once the tier is reached" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: Date.current)

    assert member.reload.user_badges.exists?(badge_key: "books_finished_1")
  end

  test "award_badges! does not re-award an already-earned badge" do
    member = users(:member)
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: Date.current)

    assert_no_difference -> { member.user_badges.where(badge_key: "books_finished_1").count } do
      member.award_badges!
    end
  end

  test "badges returns earned Badge definitions" do
    member = users(:member)
    UserBadge.create!(user: member, badge_key: "books_finished_1", awarded_at: Time.current)

    assert_equal ["books_finished_1"], member.badges.map(&:key)
  end

  test "finished_readings_count and reviews_written_count" do
    member = users(:member)
    reviews_before = member.reviews_written_count
    Reading.create!(user: member, book: books(:one), status: :finished, finished_on: Date.current)
    Reading.create!(user: member, book: books(:two), status: :finished, finished_on: Date.current, review: "Loved it")

    assert_equal 2, member.finished_readings_count
    assert_equal reviews_before + 1, member.reviews_written_count
  end
end
