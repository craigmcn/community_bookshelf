class User < ApplicationRecord
  include Clearance::User

  DEFAULT_PASSWORD = "correct-horse-shelf".freeze
  DELETED_PLACEHOLDER_EMAIL = "deleted-user@community-bookshelf.invalid"
  MAX_AVATAR_BYTES = 5.megabytes
  ALLOWED_AVATAR_TYPES = %w[image/png image/jpeg image/webp].freeze
  RESEND_COOLDOWN = 1.minute
  # Max gap, in days, between two consecutive finished books for them to
  # still count toward the same reading streak.
  STREAK_GAP_DAYS = 30

  class SoleAdminError < StandardError; end

  has_many :readings, dependent: :destroy
  has_many :books, foreign_key: :added_by_id
  has_many :shelves, dependent: :destroy
  has_many :role_assignments, dependent: :destroy
  has_many :roles, through: :role_assignments
  has_many :favorite_genres, dependent: :destroy
  has_many :favorite_genre_tags, through: :favorite_genres, source: :tag
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, inverse_of: :follower, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, inverse_of: :followed, dependent: :destroy
  has_many :followers, through: :passive_follows, source: :follower
  has_many :review_likes, dependent: :destroy
  has_many :review_comments, dependent: :destroy
  has_many :initiated_buddy_reads, class_name: "BuddyRead", foreign_key: :initiator_id, inverse_of: :initiator, dependent: :destroy
  has_many :partnered_buddy_reads, class_name: "BuddyRead", foreign_key: :partner_id, inverse_of: :partner, dependent: :destroy
  has_many :club_memberships, dependent: :destroy
  has_many :clubs, through: :club_memberships
  has_many :created_clubs, class_name: "Club", foreign_key: :created_by_id, inverse_of: :created_by
  has_many :club_posts, dependent: :destroy
  has_many :reading_challenges, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id, inverse_of: :recipient, dependent: :destroy
  # No dependent: :destroy — an audit log is a record of what an actor did,
  # not their data; deleting it when they delete their account would erase
  # the trail exactly for the accounts most likely to have used moderator
  # powers. Reassigned to the deleted-user placeholder in delete_account!
  # instead, the same treatment as books/created_clubs below.
  has_many :audit_logs, foreign_key: :actor_id, inverse_of: :actor
  has_many :api_tokens, dependent: :destroy
  has_one_attached :avatar

  # Excludes the system placeholder account from user-facing listings/stats
  # (admin user management, dashboard totals) — it isn't a real account.
  scope :excluding_deleted_placeholder, -> { where.not(email: DELETED_PLACEHOLDER_EMAIL) }

  # Set on the system placeholder account so its creation doesn't send a
  # confirmation email to an inbox nobody reads.
  attr_accessor :skip_confirmation_email

  validates :email, presence: true, uniqueness: true
  validates :name, length: {maximum: 100}
  validates :bio, length: {maximum: 500}
  validate :avatar_is_a_supported_image_under_the_size_limit

  after_create :assign_default_role
  after_create :send_email_confirmation, unless: :skip_confirmation_email
  after_save :sync_favorite_genre_list, if: -> { !@favorite_genre_list.nil? }

  # Virtual attribute: a comma-separated string of genre tag names, mirroring
  # Book#tag_list. Only touches favorite_genres when explicitly assigned, so a
  # profile update that omits it leaves existing favorites alone.
  attr_writer :favorite_genre_list

  def favorite_genre_list
    @favorite_genre_list || favorite_genre_tags.order(:name).pluck(:name).join(", ")
  end

  def admin?
    roles.exists?(name: "admin")
  end

  def moderator?
    roles.exists?(name: "moderator")
  end

  def member?
    !admin? && !moderator?
  end

  def moderator_or_above?
    moderator? || admin?
  end

  def primary_role
    return "admin" if admin?
    return "moderator" if moderator?

    "member"
  end

  # Falls back to email wherever a user's contributions are attributed, so a
  # blank display name (the common case pre-#71, and always true for the
  # deleted-account placeholder) still reads sensibly.
  def display_name
    name.presence || email
  end

  def following?(other_user)
    active_follows.exists?(followed_id: other_user.id)
  end

  def finished_readings_count
    readings.finished.count
  end

  def reviews_written_count
    readings.where.not(review: [nil, ""]).count
  end

  def current_year_challenge
    reading_challenges.find_by(year: Date.current.year)
  end

  # Consecutive finished books, most recent first, where each pair of
  # finishes is no more than STREAK_GAP_DAYS apart. A most-recent finish
  # older than that itself breaks the streak (nothing "current" to count).
  def current_streak
    finish_dates = readings.finished.where.not(finished_on: nil).order(finished_on: :desc).pluck(:finished_on)
    return 0 if finish_dates.empty?
    return 0 if finish_dates.first < STREAK_GAP_DAYS.days.ago.to_date

    streak = 1
    finish_dates.each_cons(2) do |newer, older|
      break unless (newer - older) <= STREAK_GAP_DAYS

      streak += 1
    end
    streak
  end

  def badges
    earned_keys = user_badges.pluck(:badge_key)
    Badge.list.select { |definition| earned_keys.include?(definition.key) }
  end

  # Genre tag counts across this user's finished books, for the personal
  # stats page's genre breakdown chart. A book tagged with multiple genres
  # contributes to each of them.
  def genre_breakdown
    Tag.genre.joins(books: :readings).merge(Reading.finished).where(readings: {user_id: id}).group(:name).count
  end

  # Books finished per calendar month over the last year, for the personal
  # stats page's reading-pace chart.
  def books_finished_by_month
    readings.finished.where.not(finished_on: nil).group_by_month(:finished_on, last: 12).count
  end

  # Pages read per calendar month over the last year (summed from each
  # finished book's page_count, which is optional and may be nil).
  def pages_read_by_month
    readings.finished.where.not(finished_on: nil).joins(:book).group_by_month(:finished_on, last: 12).sum("COALESCE(books.page_count, 0)")
  end

  # Checks every badge definition and records any newly-earned ones. Called
  # from Reading's after_save callback (finishing a book, writing a review)
  # rather than on a schedule — badges are permanent once earned, so this
  # only ever needs to add rows, never remove them. Two concurrent saves
  # (e.g. two requests finishing the same threshold at once) can both pass
  # the earned_keys check before either commits; the loser's create! is
  # rescued as a no-op since the badge is awarded either way.
  def award_badges!
    earned_keys = user_badges.pluck(:badge_key)
    Badge.list.each do |definition|
      next if earned_keys.include?(definition.key)
      next unless definition.criteria.call(self)

      begin
        # requires_new: true opens a savepoint — award_badges! runs inside
        # Reading's own save transaction, and a rescued RecordNotUnique still
        # leaves a plain (non-savepoint) transaction aborted at the Postgres
        # level, breaking every query the caller runs afterward in the same
        # transaction (e.g. the next badge tier's criteria check).
        ActiveRecord::Base.transaction(requires_new: true) do
          user_badges.create!(badge_key: definition.key, awarded_at: Time.current)
        end
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        next
      end
    end
  end

  def email_confirmed?
    email_confirmed_at.present?
  end

  def confirm_email!(token)
    return false if token.blank? || email_confirmation_token != token

    update!(email_confirmed_at: Time.current, email_confirmation_token: nil)
  end

  def send_email_confirmation
    update_columns(email_confirmation_token: SecureRandom.urlsafe_base64(32), email_confirmation_sent_at: Time.current)
    UserMailer.email_confirmation(self).deliver_later
  end

  def email_confirmation_on_cooldown?
    email_confirmation_sent_at.present? && email_confirmation_sent_at > RESEND_COOLDOWN.ago
  end

  # True for an admin with no other admin to hand the role to — deleting this
  # account would lock every /admin route with no recovery path short of a
  # console.
  def sole_admin?
    admin? && self.class.joins(:roles).where(roles: {name: "admin"}).where.not(id: id).none?
  end

  # Reassigns this user's contributed catalog books, any clubs they created,
  # and any audit logs where they were the acting moderator/admin to a shared
  # placeholder account (so that shared community content isn't disrupted by
  # an account deletion — a club's discussion survives its creator leaving,
  # and a moderation history survives the moderator's account leaving), then
  # destroys the user — cascading to their own readings/shelves/role
  # assignments/club posts/etc via dependent: :destroy. Readings' default
  # scope hides soft-deleted rows from that association, so they're
  # destroyed explicitly first — otherwise one left behind would still
  # reference this user's id via its FK and the final destroy! would fail.
  # Clubs need the same reassignment treatment as books — without it,
  # destroy! hits the same FK failure via clubs.created_by_id.
  def delete_account!
    raise SoleAdminError, "Can't delete the only admin account." if sole_admin?

    transaction do
      books.update_all(added_by_id: self.class.deleted_placeholder.id)
      created_clubs.update_all(created_by_id: self.class.deleted_placeholder.id)
      audit_logs.update_all(actor_id: self.class.deleted_placeholder.id)
      Reading.unscoped.where(user_id: id).destroy_all
      destroy!
    end
  end

  # Two concurrent account deletions can both miss the find below before
  # either has created this placeholder. Depending on timing, the loser's
  # create! surfaces the collision as either a real ActiveRecord::RecordNotUnique
  # (the DB unique index, if both inserts race before either commits) or an
  # ActiveRecord::RecordInvalid (the uniqueness validation, if the winner's
  # insert already committed and is merely visible in time) — verified both
  # are reachable depending on interleaving, so both are rescued here.
  def self.deleted_placeholder
    find_by(email: DELETED_PLACEHOLDER_EMAIL) || create!(
      email: DELETED_PLACEHOLDER_EMAIL,
      name: "Deleted user",
      password: SecureRandom.hex(32),
      skip_confirmation_email: true
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    find_by!(email: DELETED_PLACEHOLDER_EMAIL)
  end

  private

  def assign_default_role
    member_role = Role.find_by(name: "member")
    roles << member_role if member_role
  end

  def sync_favorite_genre_list
    names = @favorite_genre_list.to_s.split(",").filter_map { |name| name.strip.downcase.presence }.uniq
    desired_ids = names.map { |name| find_or_create_genre_tag(name).id }
    current_ids = favorite_genre_tags.pluck(:id)

    favorite_genres.where(tag_id: current_ids - desired_ids).destroy_all
    (desired_ids - current_ids).each { |tag_id| favorite_genres.create!(tag_id: tag_id) }
    @favorite_genre_list = nil
  end

  def find_or_create_genre_tag(name)
    Tag.find_or_create_by!(name: name) { |tag| tag.category = "genre" }
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    Tag.find_by!(name: name)
  end

  def avatar_is_a_supported_image_under_the_size_limit
    return unless avatar.attached?

    unless avatar.byte_size <= MAX_AVATAR_BYTES
      errors.add(:avatar, "is too large (maximum is #{MAX_AVATAR_BYTES / 1.megabyte}MB)")
    end

    unless avatar.content_type.in?(ALLOWED_AVATAR_TYPES)
      errors.add(:avatar, "must be a PNG, JPEG, or WEBP image")
    end
  end
end
