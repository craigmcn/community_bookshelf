class UserBadge < ApplicationRecord
  belongs_to :user

  validates :badge_key, presence: true, uniqueness: {scope: :user_id}, inclusion: {in: ->(_) { Badge.list.map(&:key) }}
  validates :awarded_at, presence: true

  def badge
    Badge.find(badge_key)
  end
end
