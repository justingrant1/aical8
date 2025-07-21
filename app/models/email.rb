class Email < ApplicationRecord
  belongs_to :organization
  belongs_to :email_account
  has_many :tasks, dependent: :nullify
  has_many :ai_analysis_logs, dependent: :destroy

  validates :gmail_message_id, presence: true, uniqueness: { scope: :organization_id }
  validates :gmail_thread_id, presence: true
  validates :sender_email, presence: true
  validates :received_at, presence: true
  validates :priority_level, inclusion: { in: %w[low normal high urgent] }
  validates :category, inclusion: { 
    in: %w[inspection_confirmation utility_bill work_order_update tenant_communication 
           rfta_completion rental_increase contractor_communication other] 
  }, allow_nil: true

  scope :recent, -> { order(received_at: :desc) }
  scope :high_priority, -> { where(priority_level: ['high', 'urgent']) }
  scope :urgent, -> { where(priority_level: 'urgent') }
  scope :unprocessed, -> { where(category: nil) }
  scope :processed, -> { where.not(category: nil) }
  scope :with_attachments, -> { where(has_attachments: true) }

  scope :today, -> { where(received_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(received_at: 1.week.ago..Time.current) }

  def high_priority?
    %w[high urgent].include?(priority_level)
  end

  def urgent?
    priority_level == 'urgent'
  end

  def processed?
    category.present?
  end

  def unprocessed?
    category.blank?
  end

  def high_confidence?
    confidence_score.present? && confidence_score >= 0.8
  end

  def needs_review?
    confidence_score.blank? || confidence_score < 0.7
  end

  def auto_generated_tasks
    tasks.where(is_auto_generated: true)
  end

  def sender_display_name
    sender_name.presence || sender_email
  end

  def recipients_list
    recipient_emails&.join(', ') || ''
  end

  # AI analysis results
  def latest_analysis
    ai_analysis_logs.order(created_at: :desc).first
  end

  def has_been_analyzed?
    ai_analysis_logs.exists?
  end

  # Property matching
  def matched_property
    # TODO: Implement property matching logic based on email content
    # This would analyze the email content and try to match it to properties
    nil
  end

  # Search functionality
  def self.search(query)
    return all if query.blank?

    where(
      "subject ILIKE ? OR sender_email ILIKE ? OR sender_name ILIKE ? OR body_preview ILIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
    )
  end

  def self.by_category(category)
    return all if category.blank?
    where(category: category)
  end

  def self.by_sender(email)
    return all if email.blank?
    where(sender_email: email)
  end

  # Section 8 specific methods
  def inspection_email?
    %w[inspection_confirmation].include?(category) ||
    subject_contains_inspection_keywords?
  end

  def utility_bill_email?
    category == 'utility_bill' ||
    subject_contains_utility_keywords?
  end

  def work_order_email?
    category == 'work_order_update' ||
    subject_contains_work_order_keywords?
  end

  def rfta_email?
    category == 'rfta_completion' ||
    subject.downcase.include?('rfta') ||
    subject.downcase.include?('request for tenant action')
  end

  def rental_increase_email?
    category == 'rental_increase' ||
    subject.downcase.include?('rent increase') ||
    subject.downcase.include?('rental increase')
  end

  def detect_housing_authority
    HousingAuthority.detect_from_email(sender_email, subject)
  end

  def detect_utility_company
    Utility.detect_from_email(sender_email, subject)
  end

  def extract_property_address
    # Look for address patterns in subject and body_preview
    address_patterns = [
      /\d+\s+[A-Za-z\s]+(?:Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Way|Circle|Cir|Court|Ct|Boulevard|Blvd)(?:\s+[A-Za-z0-9#\s]+)?/i,
      /\d{3,5}\s+[A-Za-z\s]+/  # Simple pattern for street numbers
    ]
    
    text_to_search = "#{subject} #{body_preview}".downcase
    
    address_patterns.each do |pattern|
      match = text_to_search.match(pattern)
      return match[0].titleize if match
    end
    
    nil
  end

  def extract_inspection_date
    # Look for date patterns in subject and body_preview
    date_patterns = [
      /(?:scheduled|inspection)\s+(?:for|on)?\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/i,
      /(\d{1,2}\/\d{1,2}\/\d{2,4})\s*(?:inspection|scheduled)/i,
      /(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday),?\s*(\d{1,2}\/\d{1,2}\/\d{2,4})/i
    ]
    
    text_to_search = "#{subject} #{body_preview}"
    
    date_patterns.each do |pattern|
      match = text_to_search.match(pattern)
      if match
        begin
          return Date.strptime(match[1], '%m/%d/%Y')
        rescue Date::Error
          begin
            return Date.strptime(match[1], '%m/%d/%y')
          rescue Date::Error
            # Skip invalid dates
          end
        end
      end
    end
    
    nil
  end

  def categorize_automatically
    return if processed?
    
    if subject_contains_inspection_keywords?
      self.category = 'inspection_confirmation'
      self.priority_level = detect_housing_authority&.priority_level || 'high'
    elsif subject_contains_utility_keywords?
      self.category = 'utility_bill'
      self.priority_level = extract_utility_priority || 'normal'
    elsif subject_contains_work_order_keywords?
      self.category = 'work_order_update'
      self.priority_level = 'normal'
    elsif rfta_email?
      self.category = 'rfta_completion'
      self.priority_level = 'high'
    elsif rental_increase_email?
      self.category = 'rental_increase'
      self.priority_level = 'normal'
    else
      self.category = 'other'
      self.priority_level = 'low'
    end
    
    save
  end

  private

  def subject_contains_inspection_keywords?
    inspection_keywords = [
      'inspection', 'reinspection', 'mha -', 'hqs', 'ghp',
      'initial reinspection', 'annual inspection', 'scheduled'
    ]
    
    inspection_keywords.any? { |keyword| subject.downcase.include?(keyword) }
  end

  def subject_contains_utility_keywords?
    utility_keywords = [
      'bill', 'payment', 'due', 'statement', 'utility',
      'alabama power', 'american water', 'spire', 'enbridge'
    ]
    
    utility_keywords.any? { |keyword| subject.downcase.include?(keyword) }
  end

  def subject_contains_work_order_keywords?
    work_order_keywords = [
      'work order', 'maintenance', 'repair', 'completed',
      'service request', 'technician'
    ]
    
    work_order_keywords.any? { |keyword| subject.downcase.include?(keyword) }
  end

  def extract_utility_priority
    # If bill is overdue or due soon, mark as urgent/high
    bill_info = Utility.extract_bill_info(body_preview, subject)
    return 'urgent' if bill_info[:due_date] && bill_info[:due_date] <= Date.current + 3.days
    
    'normal'
  end
end
