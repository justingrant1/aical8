class Organization < ApplicationRecord
  has_many :user_profiles, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :email_accounts, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :ai_analysis_logs, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, uniqueness: true, allow_blank: true
  validates :subscription_status, inclusion: { in: %w[trial active cancelled past_due] }
  validates :subscription_tier, inclusion: { in: %w[basic pro enterprise] }

  scope :active, -> { where(subscription_status: ['trial', 'active']) }

  def active_subscription?
    %w[trial active].include?(subscription_status)
  end

  def admin_users
    user_profiles.where(role: 'admin')
  end

  def can_connect_email_account?
    # Basic plan allows 1 email account, pro allows 3, enterprise unlimited
    current_count = email_accounts.count
    case subscription_tier
    when 'basic'
      current_count < 1
    when 'pro'
      current_count < 3
    else
      true
    end
  end
end
