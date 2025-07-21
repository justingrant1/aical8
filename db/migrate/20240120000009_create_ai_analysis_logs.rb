class CreateAiAnalysisLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_analysis_logs do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :email, null: true, foreign_key: true, index: true
      t.string :operation_type, null: false
      t.text :input_data
      t.json :ai_response, default: {}
      t.decimal :tokens_used, precision: 10, scale: 0, default: 0
      t.decimal :cost, precision: 10, scale: 6, default: 0.0
      t.string :model_used
      t.string :status, default: 'completed'
      t.text :error_message
      t.decimal :processing_time_seconds, precision: 8, scale: 3
      t.string :confidence_score
      t.json :metadata, default: {}
      t.timestamps
    end

    add_index :ai_analysis_logs, :operation_type
    add_index :ai_analysis_logs, :status
    add_index :ai_analysis_logs, :model_used
    add_index :ai_analysis_logs, :created_at
    add_index :ai_analysis_logs, [:organization_id, :created_at]
  end
end
