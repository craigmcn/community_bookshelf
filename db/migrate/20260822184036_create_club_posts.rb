class CreateClubPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :club_posts do |t|
      t.references :club, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.boolean :spoiler, null: false, default: false

      t.timestamps
    end

    add_index :club_posts, [:club_id, :created_at]
  end
end
