class CreateHousingAuthorities < ActiveRecord::Migration[7.0]
  def change
    create_table :housing_authorities do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :display_name, null: false
      t.text :email_domains, null: false # JSON array as text
      t.text :detection_keywords, null: false # JSON array as text
      t.string :priority_level, default: 'high'
      t.string :contact_email
      t.string :contact_phone
      t.text :contact_address
      t.string :city
      t.string :state
      t.string :website_url
      t.text :notes
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :housing_authorities, :display_name
    add_index :housing_authorities, :priority_level
    add_index :housing_authorities, :state
    add_index :housing_authorities, :active
  end
end
