class ClubPost < ApplicationRecord
  belongs_to :club
  belongs_to :user
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :body, presence: true, length: {maximum: 2000}

  after_create :notify_other_members

  # Status-based spoiler gating: a post marked spoiler is hidden from anyone
  # who hasn't finished the club's book (per their own Reading), except its
  # author and moderators. There's no page/chapter-level tracking — Reading
  # only has a status enum, not a progress marker fine-grained enough for
  # anything more precise.
  #
  # viewer_has_finished_book lets a caller looping over many posts for the
  # same viewer/club (e.g. the club show page) pass in a precomputed result
  # instead of this running an identical Reading.exists? query per post.
  def visible_to?(user, viewer_has_finished_book: nil)
    return true unless spoiler?
    return true if user == self.user || user&.moderator_or_above?

    if viewer_has_finished_book.nil?
      Reading.exists?(user_id: user&.id, book_id: club.book_id, status: :finished)
    else
      viewer_has_finished_book
    end
  end

  private

  def notify_other_members
    club.members.where.not(id: user_id).find_each do |member|
      Notification.create!(recipient: member, actor: user, notifiable: self, notification_type: :club_post)
    end
  end
end
