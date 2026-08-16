class Book < ApplicationRecord
  belongs_to :added_by, class_name: "User"
  has_many :readings, dependent: :destroy
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  # Transient — carries the selected Open Library search result's work key from
  # the form through to #create, where it's used to fetch description/subjects.
  # Not persisted, so it round-trips through a failed save/re-render like any
  # other form field.
  attr_accessor :open_library_key

  validates :title, :author, presence: true
  validates :page_count, numericality: {only_integer: true, greater_than: 0}, allow_nil: true

  after_save :sync_tags, if: :tag_list_assigned?

  # Virtual attribute: a comma-separated string of tag names, used by the book
  # form instead of exposing the tags association directly. Only touches
  # taggings when explicitly assigned (e.g. not on every update), so partial
  # updates that don't include tag_list leave existing tags alone.
  attr_writer :tag_list

  def tag_list
    @tag_list || tags.order(:name).pluck(:name).join(", ")
  end

  private

  def tag_list_assigned?
    !@tag_list.nil?
  end

  def sync_tags
    names = @tag_list.to_s.split(",").filter_map { |name| name.strip.downcase.presence }.uniq
    self.tags = names.map { |name| Tag.find_or_create_by(name: name) }
    @tag_list = nil
  end
end
