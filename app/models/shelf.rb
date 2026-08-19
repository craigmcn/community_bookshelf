class Shelf < ApplicationRecord
  belongs_to :user
  has_many :shelf_books, dependent: :destroy
  has_many :books, through: :shelf_books

  validates :name, presence: true, uniqueness: {scope: :user_id}
end
