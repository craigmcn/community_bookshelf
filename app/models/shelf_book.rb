class ShelfBook < ApplicationRecord
  belongs_to :shelf
  belongs_to :book

  validates :book_id, uniqueness: {scope: :shelf_id}
end
