class Book < ApplicationRecord
  belongs_to :added_by, class_name: "User"
  has_many :readings, dependent: :destroy

  validates :title, :author, presence: true
  validates :page_count, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
end
