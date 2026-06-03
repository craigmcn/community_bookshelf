class User < ApplicationRecord
  include Clearance::User

  has_many :readings, dependent: :destroy
  has_many :books, foreign_key: :added_by_id

  enum :role, { member: 0, moderator: 1, admin: 2 }, default: :member

  validates :email, presence: true, uniqueness: true
end
