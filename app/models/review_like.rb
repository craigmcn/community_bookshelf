class ReviewLike < ApplicationRecord
  belongs_to :user
  belongs_to :reading

  validates :user_id, uniqueness: {scope: :reading_id}
end
