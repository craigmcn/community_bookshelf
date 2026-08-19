class CreateShelfBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :shelf_books do |t|
      t.references :shelf, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true

      t.timestamps
    end
    add_index :shelf_books, [:shelf_id, :book_id], unique: true
  end
end
