# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_01_20_000009) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ai_analysis_logs", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "email_id"
    t.string "operation_type", null: false
    t.text "input_data"
    t.json "ai_response", default: {}
    t.decimal "tokens_used", precision: 10, default: "0"
    t.decimal "cost", precision: 10, scale: 6, default: "0.0"
    t.string "model_used"
    t.string "status", default: "completed"
    t.text "error_message"
    t.decimal "processing_time_seconds", precision: 8, scale: 3
    t.string "confidence_score"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_ai_analysis_logs_on_created_at"
    t.index ["email_id"], name: "index_ai_analysis_logs_on_email_id"
    t.index ["model_used"], name: "index_ai_analysis_logs_on_model_used"
    t.index ["operation_type"], name: "index_ai_analysis_logs_on_operation_type"
    t.index ["organization_id", "created_at"], name: "index_ai_analysis_logs_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_ai_analysis_logs_on_organization_id"
    t.index ["status"], name: "index_ai_analysis_logs_on_status"
  end

  create_table "email_accounts", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "email_address", null: false
    t.string "provider", default: "gmail"
    t.text "encrypted_access_token"
    t.text "encrypted_refresh_token"
    t.datetime "token_expires_at"
    t.string "gmail_history_id"
    t.json "sync_settings", default: {}
    t.datetime "last_sync_at"
    t.string "sync_status", default: "pending"
    t.text "last_error_message"
    t.integer "total_emails_processed", default: 0
    t.decimal "total_processing_cost", precision: 10, scale: 4, default: "0.0"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_email_accounts_on_active"
    t.index ["last_sync_at"], name: "index_email_accounts_on_last_sync_at"
    t.index ["organization_id", "email_address"], name: "index_email_accounts_on_organization_id_and_email_address", unique: true
    t.index ["organization_id"], name: "index_email_accounts_on_organization_id"
    t.index ["provider"], name: "index_email_accounts_on_provider"
    t.index ["sync_status"], name: "index_email_accounts_on_sync_status"
  end

  create_table "emails", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "email_account_id", null: false
    t.bigint "property_id"
    t.string "gmail_message_id", null: false
    t.string "gmail_thread_id"
    t.string "subject"
    t.string "sender_email"
    t.string "sender_name"
    t.text "recipient_emails"
    t.text "body_plain"
    t.text "body_html"
    t.datetime "email_date"
    t.string "classification"
    t.string "priority_level", default: "normal"
    t.string "sender_type"
    t.string "detected_entity_key"
    t.boolean "requires_action", default: false
    t.date "action_due_date"
    t.string "processing_status", default: "pending"
    t.text "processing_notes"
    t.json "ai_analysis", default: {}
    t.decimal "processing_cost", precision: 8, scale: 4, default: "0.0"
    t.boolean "archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_due_date"], name: "index_emails_on_action_due_date"
    t.index ["archived"], name: "index_emails_on_archived"
    t.index ["classification"], name: "index_emails_on_classification"
    t.index ["detected_entity_key"], name: "index_emails_on_detected_entity_key"
    t.index ["email_account_id"], name: "index_emails_on_email_account_id"
    t.index ["email_date"], name: "index_emails_on_email_date"
    t.index ["gmail_message_id"], name: "index_emails_on_gmail_message_id", unique: true
    t.index ["gmail_thread_id"], name: "index_emails_on_gmail_thread_id"
    t.index ["organization_id"], name: "index_emails_on_organization_id"
    t.index ["priority_level"], name: "index_emails_on_priority_level"
    t.index ["processing_status"], name: "index_emails_on_processing_status"
    t.index ["property_id"], name: "index_emails_on_property_id"
    t.index ["requires_action"], name: "index_emails_on_requires_action"
    t.index ["sender_type"], name: "index_emails_on_sender_type"
  end

  create_table "housing_authorities", force: :cascade do |t|
    t.string "key", null: false
    t.string "display_name", null: false
    t.text "email_domains", null: false
    t.text "detection_keywords", null: false
    t.string "priority_level", default: "high"
    t.string "contact_email"
    t.string "contact_phone"
    t.text "contact_address"
    t.string "city"
    t.string "state"
    t.string "website_url"
    t.text "notes"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_housing_authorities_on_active"
    t.index ["display_name"], name: "index_housing_authorities_on_display_name"
    t.index ["key"], name: "index_housing_authorities_on_key", unique: true
    t.index ["priority_level"], name: "index_housing_authorities_on_priority_level"
    t.index ["state"], name: "index_housing_authorities_on_state"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "contact_email"
    t.string "phone_number"
    t.text "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "subscription_status", default: "active"
    t.string "subscription_tier", default: "basic"
    t.datetime "subscription_expires_at"
    t.json "settings", default: {}
    t.json "billing_info", default: {}
    t.decimal "monthly_usage_cost", precision: 10, scale: 4, default: "0.0"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_organizations_on_active"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["subscription_expires_at"], name: "index_organizations_on_subscription_expires_at"
    t.index ["subscription_status"], name: "index_organizations_on_subscription_status"
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "address_line_1", null: false
    t.string "address_line_2"
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip_code", null: false
    t.string "unit_number"
    t.string "property_type", default: "single_family"
    t.string "occupancy_status", default: "vacant"
    t.decimal "monthly_rent", precision: 10, scale: 2
    t.decimal "security_deposit", precision: 10, scale: 2
    t.string "tenant_name"
    t.string "tenant_email"
    t.string "tenant_phone"
    t.date "lease_start_date"
    t.date "lease_end_date"
    t.string "housing_authority_key"
    t.string "subsidy_type"
    t.decimal "tenant_portion", precision: 10, scale: 2
    t.decimal "subsidy_portion", precision: 10, scale: 2
    t.date "last_inspection_date"
    t.date "next_inspection_date"
    t.string "inspection_status"
    t.json "metadata", default: {}
    t.text "notes"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_properties_on_active"
    t.index ["city", "state"], name: "index_properties_on_city_and_state"
    t.index ["housing_authority_key"], name: "index_properties_on_housing_authority_key"
    t.index ["next_inspection_date"], name: "index_properties_on_next_inspection_date"
    t.index ["occupancy_status"], name: "index_properties_on_occupancy_status"
    t.index ["organization_id"], name: "index_properties_on_organization_id"
    t.index ["property_type"], name: "index_properties_on_property_type"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "property_id"
    t.bigint "email_id"
    t.string "title", null: false
    t.text "description"
    t.string "task_type", null: false
    t.string "status", default: "pending"
    t.string "priority_level", default: "normal"
    t.string "assigned_to_email"
    t.string "created_by_email"
    t.date "due_date"
    t.date "completed_date"
    t.string "source", default: "email"
    t.string "source_entity_key"
    t.text "action_required"
    t.json "metadata", default: {}
    t.text "completion_notes"
    t.boolean "auto_generated", default: false
    t.decimal "estimated_cost", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_email"], name: "index_tasks_on_assigned_to_email"
    t.index ["auto_generated"], name: "index_tasks_on_auto_generated"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["email_id"], name: "index_tasks_on_email_id"
    t.index ["organization_id"], name: "index_tasks_on_organization_id"
    t.index ["priority_level"], name: "index_tasks_on_priority_level"
    t.index ["property_id"], name: "index_tasks_on_property_id"
    t.index ["source"], name: "index_tasks_on_source"
    t.index ["source_entity_key"], name: "index_tasks_on_source_entity_key"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["task_type"], name: "index_tasks_on_task_type"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "supabase_user_id", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "role", default: "viewer"
    t.string "phone_number"
    t.json "preferences", default: {}
    t.datetime "last_login_at"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_user_profiles_on_active"
    t.index ["organization_id", "email"], name: "index_user_profiles_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_user_profiles_on_organization_id"
    t.index ["role"], name: "index_user_profiles_on_role"
    t.index ["supabase_user_id"], name: "index_user_profiles_on_supabase_user_id", unique: true
  end

  create_table "utilities", force: :cascade do |t|
    t.string "company_key", null: false
    t.string "company_name", null: false
    t.text "email_domains", null: false
    t.text "detection_keywords", null: false
    t.string "utility_type", null: false
    t.string "service_area"
    t.string "customer_service_phone"
    t.string "website_url"
    t.text "bill_format_notes"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_utilities_on_active"
    t.index ["company_key"], name: "index_utilities_on_company_key", unique: true
    t.index ["company_name"], name: "index_utilities_on_company_name"
    t.index ["service_area"], name: "index_utilities_on_service_area"
    t.index ["utility_type"], name: "index_utilities_on_utility_type"
  end

  add_foreign_key "ai_analysis_logs", "emails"
  add_foreign_key "ai_analysis_logs", "organizations"
  add_foreign_key "email_accounts", "organizations"
  add_foreign_key "emails", "email_accounts"
  add_foreign_key "emails", "organizations"
  add_foreign_key "emails", "properties"
  add_foreign_key "properties", "organizations"
  add_foreign_key "tasks", "emails"
  add_foreign_key "tasks", "organizations"
  add_foreign_key "tasks", "properties"
  add_foreign_key "user_profiles", "organizations"
end
