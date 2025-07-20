class CreateEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :emails do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :email_account, null: false, foreign_key: true, index: true
      t.references :property, null: true, foreign_key: true, index: true
      t.string :gmail_message_id, null: false
      t.string :gmail_thread_id
      t.string :subject
      t.string :sender_email
      t.string :sender_name
      t.text :recipient_emails # JSON array as text
      t.text :body_plain
      t.text :body_html
      t.datetime :email_date
      t.string :classification
      t.string :priority_level, default: 'normal'
      t.string :sender_type # housing_authority, utility_company, tenant, other
      t.string :detected_entity_key # housing authority key or utility key
      t.boolean :requires_action, default: false
      t.date :action_due_date
      t.string :processing_status, default: 'pending'
      t.text :processing_notes
      t.json :ai_analysis, default: {}
      t.decimal :processing_cost, precision: 8, scale: 4, default: 0.0
      t.boolean :archived, default: false
      t.timestamps
    end

    add_index :emails, :gmail_message_id, unique: true
    add_index :emails, :gmail_thread_id
    add_index :emails, :classification
    add_index :emails, :priority_level
    add_index :emails, :sender_type
    add_index :emails, :detected_entity_key
    add_index :emails, :requires_action
    add_index :emails, :action_due_date
    add_index :emails, :processing_status
    add_index :emails, :email_date
    add_index :emails, :archived
  end
end
