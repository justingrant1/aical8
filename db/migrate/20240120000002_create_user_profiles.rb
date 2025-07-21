class CreateUserProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :user_profiles do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :supabase_user_id, null: false, index: { unique: true }
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :role, default: 'viewer'
      t.string :phone_number
      t.json :preferences, default: {}
      t.datetime :last_login_at
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :user_profiles, [:organization_id, :email], unique: true
    add_index :user_profiles, :role
    add_index :user_profiles, :active
  end
end
