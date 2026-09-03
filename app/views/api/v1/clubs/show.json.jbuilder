json.partial! "api/v1/clubs/club", club: @club, member_count: @club.club_memberships.count

# Precomputed once per render rather than inside ClubPost#visible_to? per
# post — same reasoning as the HTML ClubsController#show.
viewer_has_finished_book = Reading.exists?(user_id: current_user.id, book_id: @club.book_id, status: :finished)

json.club_posts @club.club_posts.includes(:user) do |club_post|
  visible = club_post.visible_to?(current_user, viewer_has_finished_book: viewer_has_finished_book)
  json.partial! "api/v1/clubs/club_post", club_post: club_post, visible: visible
end
