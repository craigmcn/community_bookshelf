class RemoveRedundantIndexesFromClubMembershipsAndPosts < ActiveRecord::Migration[8.1]
  def change
    # Covered by the composite index on the leading column, same reasoning
    # as RemoveRedundantIndexesFromReviewLikesAndComments.
    remove_index :club_memberships, :club_id
    remove_index :club_posts, :club_id
  end
end
