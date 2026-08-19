class AddIsReviewPublicToReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :readings, :is_review_public, :boolean, null: false, default: true
  end
end
