class CreateClubs < ActiveRecord::Migration[8.1]
  def change
    create_table :clubs do |t|
      t.string :name, null: false
      t.text :description
      t.references :book, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: {to_table: :users}

      t.timestamps
    end
  end
end
