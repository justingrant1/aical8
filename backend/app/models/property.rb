class Property < ApplicationRecord
  belongs_to :organization
  has_many :tasks, dependent: :destroy
  has_many :emails, through: :tasks

  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true
  validates :property_type, inclusion: { in: %w[residential commercial mixed_use] }
  validates :status, inclusion: { in: %w[vacant occupied maintenance offline] }

  scope :vacant, -> { where(status: 'vacant') }
  scope :occupied, -> { where(status: 'occupied') }
  scope :needs_maintenance, -> { where(status: 'maintenance') }
  scope :by_type, ->(type) { where(property_type: type) }

  def full_address
    parts = [address, unit_number, city, state, zip_code].compact
    parts.join(', ')
  end

  def short_address
    "#{address}#{unit_number.present? ? " ##{unit_number}" : ''}, #{city}"
  end

  def occupied?
    status == 'occupied'
  end

  def vacant?
    status == 'vacant'
  end

  def needs_maintenance?
    status == 'maintenance'
  end

  def lease_active?
    return false unless lease_start_date && lease_end_date
    Date.current.between?(lease_start_date, lease_end_date)
  end

  def lease_expires_soon?(days = 30)
    return false unless lease_end_date
    lease_end_date <= Date.current + days.days
  end

  def monthly_rent
    rent_amount || 0
  end

  def pending_tasks
    tasks.where(status: ['pending', 'in_progress'])
  end

  def urgent_tasks
    tasks.where(priority: 'urgent', status: ['pending', 'in_progress'])
  end

  def overdue_tasks
    tasks.where('due_date < ? AND status IN (?)', Date.current, ['pending', 'in_progress'])
  end

  # Search functionality
  def self.search(query)
    return all if query.blank?

    where(
      "address ILIKE ? OR city ILIKE ? OR tenant_name ILIKE ? OR tenant_email ILIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
    )
  end
end
