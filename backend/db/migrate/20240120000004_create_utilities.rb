class CreateUtilities < ActiveRecord::Migration[7.0]
  def change
    create_table :utilities do |t|
      t.string :company_key, null: false, index: { unique: true }
      t.string :company_name, null: false
      t.text :email_domains, null: false # JSON array as text
      t.text :detection_keywords, null: false # JSON array as text
      t.string :utility_type, null: false # electric, gas, water, etc.
      t.string :service_area # state or region
      t.string :customer_service_phone
      t.string :website_url
      t.text :bill_format_notes
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :utilities, :company_name
    add_index :utilities, :utility_type
    add_index :utilities, :service_area
    add_index :utilities, :active
  end
end
