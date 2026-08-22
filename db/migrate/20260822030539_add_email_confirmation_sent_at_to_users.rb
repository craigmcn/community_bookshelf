class AddEmailConfirmationSentAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_confirmation_sent_at, :datetime
  end
end
