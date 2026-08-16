class AddMetadataFieldsToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :isbn, :string
    add_column :books, :page_count, :integer
    add_column :books, :published_on, :date
  end
end
