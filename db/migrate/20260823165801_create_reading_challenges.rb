class CreateReadingChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_challenges do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :goal, null: false

      t.timestamps
    end

    add_index :reading_challenges, [:user_id, :year], unique: true
    add_check_constraint :reading_challenges, "goal > 0", name: "reading_challenges_goal_positive"
  end
end
