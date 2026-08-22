class CreateFavoriteGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :favorite_genres do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :favorite_genres, [:user_id, :tag_id], unique: true
  end
end
