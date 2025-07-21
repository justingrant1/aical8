class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :property, null: true, foreign_key: true, index: true
      t.references :email, null: true, foreign_key: true, index: true
      t.string :title, null: false
      t.text :description
      t.string :task_type, null: false
      t.string :status, default: 'pending'
      t.string :priority_level, default: 'normal'
      t.string :assigned_to_email
      t.string :created_by_email
      t.date :due_date
      t.date :completed_date
      t.string :source, default: 'email' # email, manual, system
      t.string :source_entity_key # housing authority key or utility key
      t.text :action_required
      t.json :metadata, default: {}
      t.text :completion_notes
      t.boolean :auto_generated, default: false
      t.decimal :estimated_cost, precision: 10, scale: 2
      t.timestamps
    end

    add_index :tasks, :task_type
    add_index :tasks, :status
    add_index :tasks, :priority_level
    add_index :tasks, :assigned_to_email
    add_index :tasks, :due_date
    add_index :tasks, :source
    add_index :tasks, :source_entity_key
    add_index :tasks, :auto_generated
  end
end
