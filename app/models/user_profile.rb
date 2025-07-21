class UserProfile < ApplicationRecord
  belongs_to :organization
  has_many :created_tasks, class_name: 'Task', foreign_key: 'created_by', dependent: :nullify
  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assigned_to', dependent: :nullify

  validates :role, inclusion: { in: %w[admin manager viewer] }
  validates :organization_id, presence: true

  scope :admins, -> { where(role: 'admin') }
  scope :managers, -> { where(role: 'manager') }
  scope :viewers, -> { where(role: 'viewer') }
  scope :active, -> { where(is_active: true) }

  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  def viewer?
    role == 'viewer'
  end

  def can_manage_properties?
    admin? || manager?
  end

  def can_manage_users?
    admin?
  end

  def can_manage_email_accounts?
    admin?
  end

  def full_name
    return email if first_name.blank? && last_name.blank?
    [first_name, last_name].compact.join(' ')
  end

  def display_name
    full_name.presence || email || "User ##{id}"
  end

  # Supabase auth.users integration
  def email
    # This would typically come from auth.users table in Supabase
    # For now, we'll store it or fetch it via Supabase client
    @email ||= fetch_email_from_auth
  end

  private

  def fetch_email_from_auth
    # TODO: Implement Supabase auth.users lookup
    # For now return a placeholder
    "user-#{id}@example.com"
  end
end
