class ClubPost < ApplicationRecord
  belongs_to :club
  belongs_to :user

  validates :body, presence: true, length: {maximum: 2000}

  # Status-based spoiler gating: a post marked spoiler is hidden from anyone
  # who hasn't finished the club's book (per their own Reading), except its
  # author and moderators. There's no page/chapter-level tracking — Reading
  # only has a status enum, not a progress marker fine-grained enough for
  # anything more precise.
  def visible_to?(user)
    return true unless spoiler?
    return true if user == self.user || user&.moderator_or_above?

    Reading.exists?(user_id: user&.id, book_id: club.book_id, status: :finished)
  end
end
