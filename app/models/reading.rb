class Reading < ApplicationRecord
  belongs_to :user
  belongs_to :book

  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscoped }

  enum :status, {want_to_read: 0, reading: 1, finished: 2}
  enum :rating, {one: 1, two: 2, three: 3, four: 4, five: 5}

  validates :status, presence: true

  def soft_delete
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
