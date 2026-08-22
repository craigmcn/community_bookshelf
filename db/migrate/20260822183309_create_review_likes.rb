class CreateReviewLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :review_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reading, null: false, foreign_key: true

      t.timestamps
    end

    add_index :review_likes, [:user_id, :reading_id], unique: true
  end
end
