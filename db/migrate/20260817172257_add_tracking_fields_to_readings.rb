class AddTrackingFieldsToReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :readings, :started_on, :date
    add_column :readings, :finished_on, :date
    add_column :readings, :progress_percent, :integer
    add_column :readings, :format, :integer
    add_check_constraint :readings, "progress_percent IS NULL OR progress_percent BETWEEN 0 AND 100", name: "readings_progress_percent_range"
  end
end
