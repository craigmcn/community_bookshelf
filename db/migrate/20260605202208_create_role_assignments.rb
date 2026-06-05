class CreateRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :role_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    add_index :role_assignments, [:user_id, :role_id], unique: true
  end
end
