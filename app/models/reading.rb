class Reading < ApplicationRecord
  belongs_to :user
  belongs_to :book
  has_many :activities, dependent: :destroy
  has_many :review_likes, dependent: :destroy
  has_many :liking_users, through: :review_likes, source: :user
  has_many :review_comments, -> { order(created_at: :asc) }, dependent: :destroy

  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscoped }

  enum :status, {want_to_read: 0, reading: 1, finished: 2, dnf: 3}
  enum :rating, {one: 1, two: 2, three: 3, four: 4, five: 5}
  enum :format, {physical: 0, ebook: 1, audiobook: 2}

  validates :status, presence: true
  validates :progress_percent, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100}, allow_nil: true
  validate :finished_on_not_before_started_on

  after_create :record_added_book_activity
  after_update :record_status_change_activity, if: :saved_change_to_status?
  after_update :record_review_activity, if: -> { review.present? && is_review_public? && review_before_last_save.blank? }
  after_save :award_badges, if: -> { saved_change_to_status? || saved_change_to_review? }

  def self.status_options
    statuses.keys.map { |s| [humanize_status(s), s] }
  end

  def self.humanize_status(status)
    (status == "dnf") ? "DNF" : status.humanize
  end

  def soft_delete
    activities.destroy_all
    review_likes.destroy_all
    review_comments.destroy_all
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def status_label
    self.class.humanize_status(status)
  end

  private

  def record_added_book_activity
    activities.create!(user: user, action: "added_book")
  end

  def record_status_change_activity
    return unless status.in?(%w[reading finished])

    activities.create!(user: user, action: (status == "reading") ? "started_reading" : "finished_reading")
  end

  def record_review_activity
    activities.create!(user: user, action: "reviewed")
  end

  def award_badges
    user.award_badges!
  end

  def finished_on_not_before_started_on
    return if started_on.blank? || finished_on.blank?

    if finished_on < started_on
      errors.add(:finished_on, "can't be before the start date")
    end
  end
end
