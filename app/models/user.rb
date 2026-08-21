class User < ApplicationRecord
  include Clearance::User

  DEFAULT_PASSWORD = "correct-horse-shelf".freeze
  DELETED_PLACEHOLDER_EMAIL = "deleted-user@community-bookshelf.invalid"
  MAX_AVATAR_BYTES = 5.megabytes
  ALLOWED_AVATAR_TYPES = %w[image/png image/jpeg image/webp].freeze

  has_many :readings, dependent: :destroy
  has_many :books, foreign_key: :added_by_id
  has_many :shelves, dependent: :destroy
  has_many :role_assignments, dependent: :destroy
  has_many :roles, through: :role_assignments
  has_one_attached :avatar

  # Set on the system placeholder account so its creation doesn't send a
  # confirmation email to an inbox nobody reads.
  attr_accessor :skip_confirmation_email

  validates :email, presence: true, uniqueness: true
  validates :name, length: {maximum: 100}
  validates :bio, length: {maximum: 500}
  validate :avatar_is_a_supported_image_under_the_size_limit

  after_create :assign_default_role
  after_create :send_email_confirmation, unless: :skip_confirmation_email

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

  def email_confirmed?
    email_confirmed_at.present?
  end

  def confirm_email!(token)
    return false if token.blank? || email_confirmation_token != token

    update!(email_confirmed_at: Time.current, email_confirmation_token: nil)
  end

  def send_email_confirmation
    update_column(:email_confirmation_token, SecureRandom.urlsafe_base64(32))
    UserMailer.email_confirmation(self).deliver_later
  end

  # Reassigns this user's contributed catalog books to a shared placeholder
  # account (so the catalog itself isn't disrupted by an account deletion),
  # then destroys the user — cascading to their own readings/shelves/role
  # assignments via dependent: :destroy.
  def delete_account!
    transaction do
      books.update_all(added_by_id: self.class.deleted_placeholder.id)
      destroy!
    end
  end

  def self.deleted_placeholder
    find_by(email: DELETED_PLACEHOLDER_EMAIL) || create!(
      email: DELETED_PLACEHOLDER_EMAIL,
      name: "Deleted user",
      password: SecureRandom.hex(32),
      skip_confirmation_email: true
    )
  end

  private

  def assign_default_role
    member_role = Role.find_by(name: "member")
    roles << member_role if member_role
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
