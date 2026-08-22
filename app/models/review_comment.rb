class ReviewComment < ApplicationRecord
  belongs_to :user
  belongs_to :reading

  validates :body, presence: true, length: {maximum: 1000}
end
