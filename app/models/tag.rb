class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :books, through: :taggings

  enum :category, {genre: "genre", mood: "mood", pace: "pace"}, default: "genre"

  before_validation { self.name = name.to_s.strip.downcase }

  validates :name, presence: true, uniqueness: true
end
