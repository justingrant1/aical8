class CreateProperties < ActiveRecord::Migration[7.0]
  def change
    create_table :properties do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip_code, null: false
      t.string :unit_number
      t.string :property_type, default: 'single_family'
      t.string :occupancy_status, default: 'vacant'
      t.decimal :monthly_rent, precision: 10, scale: 2
      t.decimal :security_deposit, precision: 10, scale: 2
      t.string :tenant_name
      t.string :tenant_email
      t.string :tenant_phone
      t.date :lease_start_date
      t.date :lease_end_date
      t.string :housing_authority_key
      t.string :subsidy_type
      t.decimal :tenant_portion, precision: 10, scale: 2
      t.decimal :subsidy_portion, precision: 10, scale: 2
      t.date :last_inspection_date
      t.date :next_inspection_date
      t.string :inspection_status
      t.json :metadata, default: {}
      t.text :notes
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :properties, :occupancy_status
    add_index :properties, :property_type
    add_index :properties, :housing_authority_key
    add_index :properties, :next_inspection_date
    add_index :properties, [:city, :state]
    add_index :properties, :active
  end
end
