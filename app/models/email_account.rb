class EmailAccount < ApplicationRecord
  belongs_to :organization
  has_many :emails, dependent: :destroy

  validates :email_address, presence: true, uniqueness: { scope: :organization_id }
  validates :provider, inclusion: { in: %w[gmail outlook] }
  validates :sync_status, inclusion: { 
    in: %w[connected syncing paused error disconnected] 
  }

  scope :active, -> { where(sync_status: ['connected', 'syncing', 'paused']) }
  scope :connected, -> { where(sync_status: 'connected') }
  scope :gmail, -> { where(provider: 'gmail') }
  scope :outlook, -> { where(provider: 'outlook') }

  before_create :set_defaults

  def connected?
    %w[connected syncing paused].include?(sync_status)
  end

  def syncing?
    sync_status == 'syncing'
  end

  def paused?
    sync_status == 'paused'
  end

  def error?
    sync_status == 'error'
  end

  def disconnected?
    sync_status == 'disconnected'
  end

  def gmail?
    provider == 'gmail'
  end

  def outlook?
    provider == 'outlook'
  end

  def needs_reauth?
    token_expires_at.present? && token_expires_at <= Time.current
  end

  def can_sync?
    connected? && !needs_reauth?
  end

  # OAuth token management
  def refresh_token_if_needed!
    return unless needs_reauth? && refresh_token.present?
    
    # TODO: Implement token refresh logic
    # This would call the appropriate OAuth provider to refresh the access token
    Rails.logger.info "Need to refresh token for #{email_address}"
  end

  def encrypt_tokens!(access_token, refresh_token = nil)
    # TODO: Implement proper encryption for storing OAuth tokens
    # For now, we'll use simple encoding (NOT PRODUCTION READY)
    self.access_token = Base64.encode64(access_token)
    self.refresh_token = Base64.encode64(refresh_token) if refresh_token
  end

  def decrypt_access_token
    return nil unless access_token.present?
    # TODO: Implement proper decryption
    Base64.decode64(access_token)
  end

  def decrypt_refresh_token
    return nil unless refresh_token.present?
    # TODO: Implement proper decryption
    Base64.decode64(refresh_token)
  end

  # Sync statistics
  def last_sync_time
    last_synced_at || created_at
  end

  def hours_since_last_sync
    return 0 unless last_synced_at
    ((Time.current - last_synced_at) / 1.hour).round
  end

  def emails_today
    emails.today.count
  end

  def emails_this_week
    emails.this_week.count
  end

  private

  def set_defaults
    self.sync_status ||= 'disconnected'
    self.sync_frequency_minutes ||= 15 # Default to 15-minute sync interval
    self.sync_full_history ||= false
  end
end
