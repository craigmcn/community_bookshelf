class CreateBuddyReadMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :buddy_read_messages do |t|
      t.references :buddy_read, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :buddy_read_messages, [:buddy_read_id, :created_at]
  end
end
