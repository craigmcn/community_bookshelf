class Book < ApplicationRecord
  belongs_to :added_by, class_name: "User"
  belongs_to :series, optional: true
  has_many :readings, dependent: :destroy

  # Transient — carries the selected Open Library search result's work key from
  # the form through to #create, where it's used to fetch description/subjects.
  # Not persisted, so it round-trips through a failed save/re-render like any
  # other form field.
  attr_accessor :open_library_key

  validates :title, :author, presence: true
  validates :page_count, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
end
