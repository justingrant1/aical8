class CreateEmailAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :email_accounts do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :email_address, null: false
      t.string :provider, default: 'gmail'
      t.text :encrypted_access_token
      t.text :encrypted_refresh_token
      t.datetime :token_expires_at
      t.string :gmail_history_id
      t.json :sync_settings, default: {}
      t.datetime :last_sync_at
      t.string :sync_status, default: 'pending'
      t.text :last_error_message
      t.integer :total_emails_processed, default: 0
      t.decimal :total_processing_cost, precision: 10, scale: 4, default: 0.0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :email_accounts, [:organization_id, :email_address], unique: true
    add_index :email_accounts, :provider
    add_index :email_accounts, :sync_status
    add_index :email_accounts, :last_sync_at
    add_index :email_accounts, :active
  end
end
