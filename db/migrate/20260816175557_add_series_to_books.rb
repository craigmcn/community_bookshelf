class AddSeriesToBooks < ActiveRecord::Migration[8.1]
  def change
    add_reference :books, :series, null: true, foreign_key: true
    add_column :books, :series_position, :integer
  end
end
