# app/controllers/api/v1/gmail_controller.rb
class Api::V1::GmailController < ApplicationController
  before_action :authenticate_user!
  before_action :check_subscription_status

  # GET /api/v1/gmail/auth_url
  # Generate Gmail OAuth authorization URL
  def auth_url
    begin
      # Generate state parameter for CSRF protection
      state = generate_oauth_state
      
      # Store state in session or cache for verification
      Rails.cache.write("oauth_state_#{current_user.id}", state, expires_in: 10.minutes)
      
      # Generate Google OAuth URL
      auth_url = google_oauth_client.authorization_uri(
        scope: gmail_scopes,
        state: state,
        access_type: 'offline',
        prompt: 'consent' # Force consent to get refresh token
      ).to_s

      render json: {
        success: true,
        auth_url: auth_url,
        state: state
      }
    rescue StandardError => e
      Rails.logger.error "Gmail auth URL generation error: #{e.message}"
      render_error('Failed to generate authorization URL', :internal_server_error)
    end
  end

  # POST /api/v1/gmail/callback
  # Handle Gmail OAuth callback
  def callback
    begin
      code = params[:code]
      state = params[:state]
      
      return render_error('Missing authorization code', :bad_request) unless code
      return render_error('Missing state parameter', :bad_request) unless state
      
      # Verify state parameter
      stored_state = Rails.cache.read("oauth_state_#{current_user.id}")
      return render_error('Invalid state parameter', :unauthorized) unless stored_state == state
      
      # Exchange code for tokens
      token_response = exchange_code_for_tokens(code)
      return render_error('Failed to exchange code for tokens', :bad_request) unless token_response
      
      # Get user info from Gmail
      gmail_user_info = get_gmail_user_info(token_response['access_token'])
      return render_error('Failed to get Gmail user info', :bad_request) unless gmail_user_info
      
      # Save or update email account
      email_account = save_email_account(token_response, gmail_user_info)
      
      if email_account
        # Clean up state
        Rails.cache.delete("oauth_state_#{current_user.id}")
        
        # Start initial email sync in background
        GmailSyncJob.perform_later(email_account.id) if defined?(GmailSyncJob)
        
        render json: {
          success: true,
          message: 'Gmail account connected successfully',
          email_account: email_account_response(email_account)
        }
      else
        render_error('Failed to save Gmail account', :unprocessable_entity)
      end
      
    rescue StandardError => e
      Rails.logger.error "Gmail callback error: #{e.message}"
      render_error('OAuth callback failed', :internal_server_error)
    end
  end

  # GET /api/v1/gmail/accounts
  # List connected Gmail accounts for organization
  def accounts
    email_accounts = current_organization.email_accounts.includes(:user_profile)
    
    render json: {
      success: true,
      accounts: email_accounts.map { |account| email_account_response(account) }
    }
  end

  # DELETE /api/v1/gmail/accounts/:id
  # Disconnect Gmail account
  def disconnect
    email_account = current_organization.email_accounts.find(params[:id])
    
    if email_account
      # Revoke token with Google
      revoke_google_token(email_account.access_token) if email_account.access_token
      
      # Delete the account
      email_account.destroy
      
      render json: {
        success: true,
        message: 'Gmail account disconnected successfully'
      }
    else
      render_error('Gmail account not found', :not_found)
    end
  end

  # POST /api/v1/gmail/sync
  # Trigger manual email sync
  def sync
    email_account_id = params[:email_account_id]
    
    if email_account_id
      email_account = current_organization.email_accounts.find(email_account_id)
      return render_error('Gmail account not found', :not_found) unless email_account
      
      # Queue sync job
      GmailSyncJob.perform_later(email_account.id) if defined?(GmailSyncJob)
      
      render json: {
        success: true,
        message: 'Email sync started'
      }
    else
      # Sync all accounts for organization
      current_organization.email_accounts.find_each do |account|
        GmailSyncJob.perform_later(account.id) if defined?(GmailSyncJob)
      end
      
      render json: {
        success: true,
        message: 'Email sync started for all accounts'
      }
    end
  end

  # GET /api/v1/gmail/sync_status
  # Check sync status for accounts
  def sync_status
    email_accounts = current_organization.email_accounts
    
    status_data = email_accounts.map do |account|
      {
        id: account.id,
        email: account.email,
        last_sync_at: account.last_sync_at,
        sync_status: account.sync_status || 'idle',
        sync_error: account.sync_error,
        email_count: account.emails.count,
        last_email_date: account.emails.maximum(:sent_at)
      }
    end
    
    render json: {
      success: true,
      accounts: status_data
    }
  end

  private

  def google_oauth_client
    @google_oauth_client ||= Signet::OAuth2::Client.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      authorization_uri: 'https://accounts.google.com/o/oauth2/v2/auth',
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      redirect_uri: gmail_callback_url
    )
  end

  def gmail_callback_url
    # Use Rails API callback URL that matches our routes
    if Rails.env.development?
      "http://localhost:3000/api/v1/gmail/callback"
    else
      "#{ENV['API_BASE_URL'] || ENV['FRONTEND_URL']}/api/v1/gmail/callback"
    end
  end

  def gmail_scopes
    [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.modify',
      'https://www.googleapis.com/auth/userinfo.email'
    ]
  end

  def generate_oauth_state
    SecureRandom.urlsafe_base64(32)
  end

  def exchange_code_for_tokens(code)
    client = google_oauth_client
    client.code = code
    
    response = client.fetch_access_token!
    response
  rescue StandardError => e
    Rails.logger.error "Token exchange error: #{e.message}"
    nil
  end

  def get_gmail_user_info(access_token)
    uri = URI('https://www.googleapis.com/oauth2/v2/userinfo')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "Gmail user info error: #{response.code} #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Gmail user info error: #{e.message}"
    nil
  end

  def save_email_account(token_response, gmail_user_info)
    email = gmail_user_info['email']
    
    # Find existing account or create new one
    email_account = current_organization.email_accounts.find_or_initialize_by(
      email: email
    )
    
    email_account.assign_attributes(
      user_profile: current_user,
      access_token: encrypt_token(token_response['access_token']),
      refresh_token: encrypt_token(token_response['refresh_token']),
      token_expires_at: Time.current + token_response['expires_in'].seconds,
      gmail_user_id: gmail_user_info['id'],
      is_active: true,
      sync_status: 'pending',
      token_scopes: gmail_scopes
    )
    
    email_account.save ? email_account : nil
  rescue StandardError => e
    Rails.logger.error "Save email account error: #{e.message}"
    nil
  end

  def revoke_google_token(encrypted_token)
    access_token = decrypt_token(encrypted_token)
    return unless access_token
    
    uri = URI('https://oauth2.googleapis.com/revoke')
    
    response = Net::HTTP.post_form(uri, 'token' => access_token)
    Rails.logger.info "Token revocation response: #{response.code}"
  rescue StandardError => e
    Rails.logger.error "Token revocation error: #{e.message}"
  end

  def encrypt_token(token)
    return nil unless token
    
    # Use Rails built-in encryption
    Rails.application.message_encryptor(:tokens).encrypt_and_sign(token)
  end

  def decrypt_token(encrypted_token)
    return nil unless encrypted_token
    
    Rails.application.message_encryptor(:tokens).decrypt_and_verify(encrypted_token)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    Rails.logger.error "Token decryption failed"
    nil
  end

  def email_account_response(email_account)
    {
      id: email_account.id,
      email: email_account.email,
      gmail_user_id: email_account.gmail_user_id,
      is_active: email_account.is_active,
      connected_at: email_account.created_at,
      last_sync_at: email_account.last_sync_at,
      sync_status: email_account.sync_status,
      sync_error: email_account.sync_error,
      connected_by: {
        id: email_account.user_profile.id,
        name: "#{email_account.user_profile.first_name} #{email_account.user_profile.last_name}".strip,
        email: email_account.user_profile.email
      },
      token_expires_at: email_account.token_expires_at,
      email_count: email_account.emails.count
    }
  end

  def check_subscription_status
    unless current_organization.subscription_active?
      render_error('Subscription required for Gmail integration', :payment_required)
    end
  end
end
