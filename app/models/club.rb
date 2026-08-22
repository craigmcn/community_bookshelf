class Club < ApplicationRecord
  belongs_to :book
  belongs_to :created_by, class_name: "User"
  has_many :club_memberships, dependent: :destroy
  has_many :members, through: :club_memberships, source: :user
  has_many :club_posts, -> { order(created_at: :desc) }, dependent: :destroy

  validates :name, presence: true, length: {maximum: 100}
  validates :description, length: {maximum: 1000}

  after_create :add_creator_as_member

  def member?(user)
    user && club_memberships.exists?(user_id: user.id)
  end

  private

  def add_creator_as_member
    club_memberships.create!(user: created_by)
  end
end
