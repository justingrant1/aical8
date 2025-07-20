class Task < ApplicationRecord
  belongs_to :organization
  belongs_to :property, optional: true
  belongs_to :email, optional: true
  belongs_to :assigned_to, class_name: 'UserProfile', foreign_key: 'assigned_to', optional: true
  belongs_to :created_by, class_name: 'UserProfile', foreign_key: 'created_by', optional: true
  belongs_to :housing_authority, optional: true

  # Section 8 specific validations
  validates :inspection_type, inclusion: { 
    in: %w[annual initial re_inspection hqs work_order utility other] 
  }, allow_nil: true
  validates :utility_company, inclusion: { 
    in: %w[alabama_power american_water spire montgomery_water_works enbridge other] 
  }, allow_nil: true

  validates :title, presence: true
  validates :task_type, inclusion: { 
    in: %w[inspection_annual inspection_initial inspection_reinspection inspection_hqs 
           utility_payment work_order maintenance compliance leasing financial 
           tenant_communication other] 
  }
  validates :status, inclusion: { 
    in: %w[pending in_progress completed cancelled] 
  }
  validates :priority, inclusion: { 
    in: %w[low normal high urgent] 
  }

  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :active, -> { where(status: ['pending', 'in_progress']) }

  scope :urgent, -> { where(priority: 'urgent') }
  scope :high_priority, -> { where(priority: ['high', 'urgent']) }

  scope :overdue, -> { where('due_date < ? AND status IN (?)', Date.current, ['pending', 'in_progress']) }
  scope :due_soon, ->(days = 3) { 
    where('due_date BETWEEN ? AND ? AND status IN (?)', 
          Date.current, Date.current + days.days, ['pending', 'in_progress']) 
  }

  scope :auto_generated, -> { where(is_auto_generated: true) }
  scope :manual, -> { where(is_auto_generated: false) }

  scope :by_type, ->(type) { where(task_type: type) }
  scope :for_property, ->(property_id) { where(property_id: property_id) }

  # Section 8 specific scopes
  scope :inspections, -> { where(task_type: ['inspection_annual', 'inspection_initial', 'inspection_reinspection', 'inspection_hqs']) }
  scope :reinspections, -> { where(task_type: 'inspection_reinspection') }
  scope :utility_bills, -> { where(task_type: 'utility_payment') }
  scope :work_orders, -> { where(task_type: 'work_order') }
  scope :by_housing_authority, ->(authority_id) { where(housing_authority_id: authority_id) }
  scope :by_utility_company, ->(company) { where(utility_company: company) }

  def pending?
    status == 'pending'
  end

  def in_progress?
    status == 'in_progress'
  end

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def active?
    pending? || in_progress?
  end

  def overdue?
    due_date.present? && due_date < Date.current && active?
  end

  def due_soon?(days = 3)
    due_date.present? && due_date <= Date.current + days.days && active?
  end

  def urgent?
    priority == 'urgent'
  end

  def high_priority?
    %w[high urgent].include?(priority)
  end

  def auto_generated?
    is_auto_generated
  end

  def days_until_due
    return nil unless due_date
    (due_date - Date.current).to_i
  end

  def complete!
    update!(status: 'completed', completed_at: Time.current)
  end

  def assign_to!(user_profile)
    update!(assigned_to: user_profile)
  end

  # AI-related methods
  def ai_generated?
    auto_generated? && ai_confidence.present?
  end

  def high_confidence_ai?
    ai_confidence.present? && ai_confidence >= 0.8
  end

  def needs_review?
    ai_generated? && (ai_confidence.nil? || ai_confidence < 0.7)
  end

  # Section 8 specific methods
  def inspection_task?
    %w[inspection_annual inspection_initial inspection_reinspection inspection_hqs].include?(task_type)
  end

  def reinspection?
    task_type == 'inspection_reinspection'
  end

  def utility_bill?
    task_type == 'utility_payment'
  end

  def work_order?
    task_type == 'work_order'
  end

  def critical_inspection?
    reinspection? || (inspection_task? && urgent?)
  end

  def display_address
    property_address.presence || property&.address || 'Address not available'
  end

  def housing_authority_name
    housing_authority&.name || 'Unknown Authority'
  end

  def formatted_utility_company
    return nil unless utility_company
    utility_company.humanize.titleize
  end

  # Search functionality
  def self.search(query)
    return all if query.blank?

    joins(:property)
      .where(
        "tasks.title ILIKE ? OR tasks.description ILIKE ? OR properties.address ILIKE ?",
        "%#{query}%", "%#{query}%", "%#{query}%"
      )
  end
end
