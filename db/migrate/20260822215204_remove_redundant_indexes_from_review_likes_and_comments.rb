class RemoveRedundantIndexesFromReviewLikesAndComments < ActiveRecord::Migration[8.1]
  def change
    # Covered by the composite index on the leading column — see the two
    # create_table migrations for the leftmost-prefix reasoning.
    remove_index :review_comments, :reading_id
    remove_index :review_likes, :user_id
  end
end
