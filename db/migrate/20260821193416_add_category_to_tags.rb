class AddCategoryToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :category, :string, null: false, default: "genre"
    add_index :tags, :category
  end
end
