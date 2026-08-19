class Reading < ApplicationRecord
  belongs_to :user
  belongs_to :book

  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscoped }

  enum :status, {want_to_read: 0, reading: 1, finished: 2, dnf: 3}
  enum :rating, {one: 1, two: 2, three: 3, four: 4, five: 5}
  enum :format, {physical: 0, ebook: 1, audiobook: 2}

  validates :status, presence: true
  validates :progress_percent, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100}, allow_nil: true
  validate :finished_on_not_before_started_on

  def self.status_options
    statuses.keys.map { |s| [humanize_status(s), s] }
  end

  def self.humanize_status(status)
    (status == "dnf") ? "DNF" : status.humanize
  end

  def soft_delete
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def status_label
    self.class.humanize_status(status)
  end

  private

  def finished_on_not_before_started_on
    return if started_on.blank? || finished_on.blank?

    if finished_on < started_on
      errors.add(:finished_on, "can't be before the start date")
    end
  end
end
