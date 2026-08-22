class CreateReviewComments < ActiveRecord::Migration[8.1]
  def change
    create_table :review_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reading, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :review_comments, [:reading_id, :created_at]
  end
end
