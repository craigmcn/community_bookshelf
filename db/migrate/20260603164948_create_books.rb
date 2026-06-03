class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.string :cover_url
      t.references :added_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
