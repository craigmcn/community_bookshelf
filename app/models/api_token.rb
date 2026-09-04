class ApiToken < ApplicationRecord
  SCOPES = %w[read:books write:books read:readings write:readings read:shelves write:shelves write:follows
    read:reading_challenges write:reading_challenges read:stats read:clubs write:clubs
    read:buddy_reads write:buddy_reads read:notifications write:notifications].freeze
  TOKEN_PREFIX = "cb_"
  # 8 hex chars of the secret, in addition to the fixed TOKEN_PREFIX literal —
  # enough entropy that prefix collisions are statistically irrelevant, while
  # staying short enough to show as a display fragment (cb_a1b2c3d4...).
  DISPLAY_PREFIX_LENGTH = TOKEN_PREFIX.length + 8
  LAST_USED_STALENESS = 5.minutes

  belongs_to :user

  validates :name, presence: true
  validates :token_digest, :token_prefix, presence: true
  validates :scopes, presence: true
  validate :scopes_are_known

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  # Not persisted — set only on the instance returned by .generate!, so the
  # caller can display the full secret exactly once. Every other read of an
  # ApiToken (index listing, authenticate lookup) never has this populated.
  attr_accessor :plaintext_token

  def self.generate!(user:, name:, scopes:, expires_at: nil)
    secret = TOKEN_PREFIX + SecureRandom.hex(24)

    create!(
      user: user,
      name: name,
      scopes: scopes,
      expires_at: expires_at,
      token_prefix: secret[0, DISPLAY_PREFIX_LENGTH],
      token_digest: BCrypt::Password.create(secret)
    ).tap { |token| token.plaintext_token = secret }
  end

  # Narrows the lookup to an indexed column first, since bcrypt comparison is
  # deliberately slow and shouldn't run against every token in the table.
  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    token = active.find_by(token_prefix: raw_token[0, DISPLAY_PREFIX_LENGTH])
    token if token && BCrypt::Password.new(token.token_digest) == raw_token
  end

  def expired?
    expires_at.present? && expires_at.past?
  end

  # Skips the write when already touched recently — a token authenticated on
  # every request (up to 120/min under the API throttle) would otherwise
  # issue a DB write on every single one, just to update a display field.
  def touch_last_used!
    return if last_used_at.present? && last_used_at > LAST_USED_STALENESS.ago

    update_column(:last_used_at, Time.current)
  end

  private

  def scopes_are_known
    unknown = Array(scopes) - SCOPES
    errors.add(:scopes, "contains unknown scope(s): #{unknown.join(", ")}") if unknown.any?
  end
end
