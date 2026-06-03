class Book < ApplicationRecord
  belongs_to :added_by, class_name: "User"
  has_many :readings, dependent: :destroy

  validates :title, :author, presence: true
end
