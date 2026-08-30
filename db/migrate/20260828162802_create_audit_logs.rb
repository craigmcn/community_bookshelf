class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :actor, null: false, foreign_key: {to_table: :users}
      t.string :action, null: false
      t.references :subject, polymorphic: true, null: false
      t.jsonb :details, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, :created_at
  end
end
