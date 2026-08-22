class CreateBuddyReads < ActiveRecord::Migration[8.1]
  def change
    create_table :buddy_reads do |t|
      t.references :book, null: false, foreign_key: true
      t.references :initiator, null: false, foreign_key: {to_table: :users}
      t.references :partner, null: false, foreign_key: {to_table: :users}
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_check_constraint :buddy_reads, "initiator_id <> partner_id", name: "buddy_reads_no_self_pair"
  end
end
