class Utility < ApplicationRecord
  belongs_to :organization
  belongs_to :property
  has_many :tasks, -> { where(task_type: 'utility_payment') }, foreign_key: 'property_id', primary_key: 'property_id'

  validates :company_name, presence: true
  validates :utility_type, inclusion: { 
    in: %w[electric gas water sewer internet cable trash other] 
  }
  validates :account_number, presence: true

  # Based on user's email screenshots
  COMPANY_MAPPINGS = {
    'alabama_power' => {
      name: 'Alabama Power',
      type: 'electric',
      email_patterns: ['Alabama Power', 'alabamapower']
    },
    'american_water' => {
      name: 'American Water',
      type: 'water',
      email_patterns: ['American Water', 'amwater']
    },
    'spire' => {
      name: 'Spire Energy',
      type: 'gas',
      email_patterns: ['Spire', 'SpireEnergy.com']
    },
    'montgomery_water_works' => {
      name: 'Montgomery Water Works',
      type: 'water',
      email_patterns: ['Montgomery Water Works', 'mgmwaterworks']
    },
    'enbridge' => {
      name: 'Enbridge Gas Ohio',
      type: 'gas',
      email_patterns: ['Enbridge', 'Enbridge Gas Ohio']
    }
  }.freeze

  scope :active, -> { where(is_active: true) }
  scope :by_type, ->(type) { where(utility_type: type) }
  scope :by_company, ->(company) { where(company_name: company) }
  scope :auto_pay_enabled, -> { where(auto_pay_enabled: true) }

  def display_name
    "#{company_name} - #{utility_type.titleize}"
  end

  def formatted_account_number
    return account_number if account_number.length < 8
    "****#{account_number.last(4)}"
  end

  def days_until_due(due_date)
    return nil unless due_date
    (due_date.to_date - Date.current).to_i
  end

  def overdue?(due_date)
    return false unless due_date
    due_date.to_date < Date.current
  end

  def self.detect_from_email(sender_email, subject_line)
    COMPANY_MAPPINGS.each do |key, config|
      patterns = config[:email_patterns]
      if patterns.any? { |pattern| sender_email.include?(pattern) || subject_line.include?(pattern) }
        return {
          company_key: key,
          company_name: config[:name],
          utility_type: config[:type]
        }
      end
    end
    nil
  end

  def self.extract_bill_info(email_body, subject_line)
    bill_info = {}
    
    # Extract amount due - common patterns
    amount_patterns = [
      /amount due[:\s]+\$?(\d+\.?\d*)/i,
      /due[:\s]+\$(\d+\.?\d*)/i,
      /balance[:\s]+\$(\d+\.?\d*)/i,
      /\$(\d+\.?\d*)\s*due/i
    ]
    
    amount_patterns.each do |pattern|
      if match = (email_body || subject_line).match(pattern)
        bill_info[:amount] = match[1].to_f
        break
      end
    end
    
    # Extract due date - common patterns
    date_patterns = [
      /due\s+date[:\s]+(\d{1,2}\/\d{1,2}\/\d{2,4})/i,
      /due\s+by[:\s]+(\d{1,2}\/\d{1,2}\/\d{2,4})/i,
      /payment\s+due[:\s]+(\d{1,2}\/\d{1,2}\/\d{2,4})/i,
      /due[:\s]+(\d{1,2}\/\d{1,2}\/\d{2,4})/i
    ]
    
    date_patterns.each do |pattern|
      if match = (email_body || subject_line).match(pattern)
        begin
          bill_info[:due_date] = Date.strptime(match[1], '%m/%d/%Y')
        rescue Date::Error
          begin
            bill_info[:due_date] = Date.strptime(match[1], '%m/%d/%y')
          rescue Date::Error
            # Skip invalid dates
          end
        end
        break
      end
    end
    
    # Extract account number patterns
    account_patterns = [
      /account\s+number[:\s]+(\d+)/i,
      /account[:\s#]+(\d+)/i
    ]
    
    account_patterns.each do |pattern|
      if match = (email_body || subject_line).match(pattern)
        bill_info[:account_number] = match[1]
        break
      end
    end
    
    bill_info
  end

  def priority_level(due_date)
    return 'low' unless due_date
    
    days_until = days_until_due(due_date)
    
    case days_until
    when nil
      'low'
    when ...0
      'urgent'  # Overdue
    when 0..2
      'urgent'  # Due in 2 days or less
    when 3..7
      'high'    # Due within a week
    else
      'normal'  # More than a week
    end
  end
end
