class CreateClubMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :club_memberships do |t|
      t.references :club, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :club_memberships, [:club_id, :user_id], unique: true
  end
end
