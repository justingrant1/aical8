class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :contact_email
      t.string :phone_number
      t.text :address
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :subscription_status, default: 'active'
      t.string :subscription_tier, default: 'basic'
      t.datetime :subscription_expires_at
      t.json :settings, default: {}
      t.json :billing_info, default: {}
      t.decimal :monthly_usage_cost, precision: 10, scale: 4, default: 0.0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :organizations, :subscription_status
    add_index :organizations, :subscription_expires_at
    add_index :organizations, :active
  end
end
