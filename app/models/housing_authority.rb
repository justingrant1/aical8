class HousingAuthority < ApplicationRecord
  belongs_to :organization
  has_many :tasks
  has_many :properties, through: :tasks

  validates :name, presence: true
  validates :authority_type, inclusion: { 
    in: %w[mha hqs ghp other] 
  }

  # Email pattern examples based on user's screenshots:
  # "MHA - Initial Reinspection Scheduled"
  # "HQS Inspection"
  # "GHP Inspections"
  serialize :email_subject_patterns, Array
  serialize :inspector_contacts, Array

  scope :active, -> { where(is_active: true) }
  scope :by_type, ->(type) { where(authority_type: type) }

  def display_name
    case authority_type
    when 'mha'
      'Montgomery Housing Authority (MHA)'
    when 'hqs' 
      'Housing Quality Standards (HQS)'
    when 'ghp'
      'GHP Inspections'
    else
      name
    end
  end

  def matches_email_pattern?(subject_line)
    return false if email_subject_patterns.blank?
    
    email_subject_patterns.any? do |pattern|
      subject_line.downcase.include?(pattern.downcase)
    end
  end

  def default_notice_days
    case authority_type
    when 'mha'
      3  # MHA typically gives 3 days notice
    when 'hqs'
      5  # HQS gives more notice
    when 'ghp'
      2  # GHP is often shorter notice
    else
      3
    end
  end

  def priority_level
    case authority_type
    when 'mha'
      'high'  # MHA inspections are critical
    when 'hqs'
      'normal'
    when 'ghp'
      'high'
    else
      'normal'
    end
  end

  # Based on user's email patterns
  def self.detect_from_email(sender_email, subject_line)
    # Check for MHA patterns
    if subject_line.include?('MHA -') || sender_email.include?('mhatoday')
      find_or_create_mha_authority
    # Check for HQS patterns  
    elsif subject_line.include?('HQS') || sender_email.include?('inspection@gilsonhousingpartners')
      find_or_create_hqs_authority
    # Check for GHP patterns
    elsif subject_line.include?('GHP') || sender_email.include?('ghp')
      find_or_create_ghp_authority
    else
      nil
    end
  end

  private

  def self.find_or_create_mha_authority
    find_or_create_by(
      authority_type: 'mha',
      name: 'Montgomery Housing Authority'
    ) do |authority|
      authority.email_subject_patterns = [
        'MHA - Initial Reinspection',
        'MHA - Annual Inspection', 
        'MHA - Initial Inspection'
      ]
      authority.contact_email = 'inspection@mhatoday.org'
      authority.typical_notice_days = 3
      authority.is_active = true
    end
  end

  def self.find_or_create_hqs_authority
    find_or_create_by(
      authority_type: 'hqs',
      name: 'HQS Inspection'
    ) do |authority|
      authority.email_subject_patterns = [
        'HQS Inspection'
      ]
      authority.contact_email = 'inspection@gilsonhousingpartners.com'
      authority.typical_notice_days = 5
      authority.is_active = true
    end
  end

  def self.find_or_create_ghp_authority
    find_or_create_by(
      authority_type: 'ghp', 
      name: 'GHP Inspections'
    ) do |authority|
      authority.email_subject_patterns = [
        'GHP Inspections'
      ]
      authority.typical_notice_days = 2
      authority.is_active = true
    end
  end
end
