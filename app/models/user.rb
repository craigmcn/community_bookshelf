class User < ApplicationRecord
  include Clearance::User

  DEFAULT_PASSWORD = "correct-horse-shelf".freeze

  has_many :readings, dependent: :destroy
  has_many :books, foreign_key: :added_by_id
  has_many :shelves, dependent: :destroy
  has_many :role_assignments, dependent: :destroy
  has_many :roles, through: :role_assignments

  validates :email, presence: true, uniqueness: true

  after_create :assign_default_role

  def admin?
    roles.exists?(name: "admin")
  end

  def moderator?
    roles.exists?(name: "moderator")
  end

  def member?
    !admin? && !moderator?
  end

  def moderator_or_above?
    moderator? || admin?
  end

  def primary_role
    return "admin" if admin?
    return "moderator" if moderator?

    "member"
  end

  private

  def assign_default_role
    member_role = Role.find_by(name: "member")
    roles << member_role if member_role
  end
end
