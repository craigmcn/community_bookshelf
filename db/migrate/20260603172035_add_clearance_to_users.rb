class AddClearanceToUsers < ActiveRecord::Migration[8.1]
  def self.up
    change_table :users do |t|
      t.string :encrypted_password, limit: 128
      t.string :confirmation_token, limit: 128
      t.string :remember_token, limit: 128
    end
    add_index :users, :confirmation_token, unique: true
    add_index :users, :remember_token, unique: true
    Clearance.configuration.user_model.where(remember_token: nil).find_each do |user|
      user.update_columns(remember_token: Clearance::Token.new)
    end
  end

  def self.down
    remove_index :users, :confirmation_token, unique: true
    remove_index :users, :remember_token, unique: true
    change_table :users do |t|
      t.remove :encrypted_password
      t.remove :confirmation_token
      t.remove :remember_token
    end
  end
end
