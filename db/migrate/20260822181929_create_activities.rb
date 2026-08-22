class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reading, null: false, foreign_key: true
      t.string :action, null: false

      t.timestamps
    end

    add_index :activities, [:user_id, :created_at]
  end
end
