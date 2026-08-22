class ClubMembership < ApplicationRecord
  belongs_to :club
  belongs_to :user

  validates :user_id, uniqueness: {scope: :club_id}
end
