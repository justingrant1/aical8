class GmailService
  include HTTParty
  base_uri 'https://gmail.googleapis.com'

  def initialize(email_account)
    @email_account = email_account
    @access_token = email_account.decrypt_access_token
  end

  # OAuth2 token refresh
  def refresh_access_token!
    return false unless @email_account.refresh_token.present?

    response = self.class.post('/oauth2/v4/token', {
      body: {
        client_id: Rails.application.config.google_client_id,
        client_secret: Rails.application.config.google_client_secret,
        refresh_token: @email_account.decrypt_refresh_token,
        grant_type: 'refresh_token'
      },
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    })

    if response.success?
      data = JSON.parse(response.body)
      @email_account.encrypt_tokens!(
        data['access_token'], 
        data['refresh_token'] || @email_account.decrypt_refresh_token
      )
      @email_account.update!(
        token_expires_at: Time.current + data['expires_in'].seconds,
        sync_status: 'connected'
      )
      @access_token = data['access_token']
      true
    else
      @email_account.update!(sync_status: 'error', last_error: response.body)
      false
    end
  end

  # Fetch recent emails
  def fetch_recent_emails(limit: 50)
    return [] unless @access_token

    # Refresh token if needed
    refresh_access_token! if @email_account.needs_reauth?

    response = self.class.get('/gmail/v1/users/me/messages', {
      query: { 
        maxResults: limit,
        q: build_search_query
      },
      headers: headers
    })

    if response.success?
      data = JSON.parse(response.body)
      messages = data['messages'] || []
      
      # Fetch full message details for each
      messages.map do |msg|
        fetch_message_details(msg['id'])
      end.compact
    else
      Rails.logger.error "Gmail API Error: #{response.body}"
      []
    end
  end

  # Fetch specific message details
  def fetch_message_details(message_id)
    response = self.class.get("/gmail/v1/users/me/messages/#{message_id}", {
      headers: headers
    })

    if response.success?
      parse_gmail_message(JSON.parse(response.body))
    else
      Rails.logger.error "Failed to fetch message #{message_id}: #{response.body}"
      nil
    end
  end

  # Set up Gmail push notifications
  def setup_push_notifications(webhook_url)
    response = self.class.post('/gmail/v1/users/me/watch', {
      body: {
        topicName: "projects/#{ENV['GOOGLE_CLOUD_PROJECT_ID']}/topics/gmail-notifications",
        labelIds: ['INBOX']
      }.to_json,
      headers: headers.merge('Content-Type' => 'application/json')
    })

    if response.success?
      data = JSON.parse(response.body)
      @email_account.update!(
        gmail_history_id: data['historyId'],
        webhook_expires_at: Time.at(data['expiration'].to_i / 1000)
      )
      true
    else
      Rails.logger.error "Failed to setup push notifications: #{response.body}"
      false
    end
  end

  # Process incoming webhook notification
  def self.process_webhook_notification(data, email_account)
    # This would be called from the webhook controller
    # to process new email notifications from Gmail
    service = new(email_account)
    service.sync_new_messages(data['historyId'])
  end

  def sync_new_messages(since_history_id = nil)
    @email_account.update!(sync_status: 'syncing')
    
    begin
      history_id = since_history_id || @email_account.gmail_history_id
      
      if history_id
        sync_history_changes(history_id)
      else
        # Full sync if no history ID
        fetch_and_store_emails
      end
      
      @email_account.update!(
        sync_status: 'connected',
        last_synced_at: Time.current,
        last_error: nil
      )
      
    rescue => e
      Rails.logger.error "Gmail sync error: #{e.message}"
      @email_account.update!(
        sync_status: 'error',
        last_error: e.message
      )
      raise e
    end
  end

  private

  def headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def build_search_query
    # Focus on property management related emails
    terms = [
      'subject:(maintenance OR repair OR lease OR rent OR tenant OR property)',
      'from:(management OR landlord OR tenant OR contractor)',
      'newer_than:7d' # Last 7 days
    ]
    terms.join(' ')
  end

  def parse_gmail_message(gmail_data)
    payload = gmail_data['payload']
    headers = payload['headers']
    
    subject = find_header_value(headers, 'Subject')
    from = find_header_value(headers, 'From')
    to = find_header_value(headers, 'To')
    date = find_header_value(headers, 'Date')
    
    # Extract sender email and name
    sender_match = from&.match(/(.+?)\s*<(.+?)>/) || from&.match(/(.+)/)
    sender_name = sender_match ? sender_match[1]&.strip&.gsub(/^["']|["']$/, '') : nil
    sender_email = sender_match && sender_match[2] ? sender_match[2].strip : from

    # Parse recipients
    recipient_emails = parse_email_addresses(to)
    
    # Extract body
    body_data = extract_email_body(payload)
    
    {
      gmail_message_id: gmail_data['id'],
      gmail_thread_id: gmail_data['threadId'],
      subject: subject,
      sender_name: sender_name,
      sender_email: sender_email,
      recipient_emails: recipient_emails,
      received_at: parse_gmail_date(date),
      body_text: body_data[:text],
      body_html: body_data[:html],
      body_preview: generate_preview(body_data[:text] || body_data[:html]),
      has_attachments: has_attachments?(payload),
      gmail_labels: gmail_data['labelIds'] || []
    }
  end

  def find_header_value(headers, name)
    header = headers.find { |h| h['name'].downcase == name.downcase }
    header&.dig('value')
  end

  def parse_email_addresses(email_string)
    return [] unless email_string
    
    # Simple email extraction - could be enhanced
    email_string.scan(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/i)
  end

  def extract_email_body(payload)
    text_body = nil
    html_body = nil
    
    if payload['body']['data']
      # Simple email body
      decoded = Base64.urlsafe_decode64(payload['body']['data'])
      text_body = decoded if payload['mimeType'] == 'text/plain'
      html_body = decoded if payload['mimeType'] == 'text/html'
    elsif payload['parts']
      # Multipart email
      payload['parts'].each do |part|
        case part['mimeType']
        when 'text/plain'
          text_body = Base64.urlsafe_decode64(part['body']['data']) if part['body']['data']
        when 'text/html'
          html_body = Base64.urlsafe_decode64(part['body']['data']) if part['body']['data']
        end
      end
    end
    
    { text: text_body, html: html_body }
  end

  def generate_preview(body_text, limit = 200)
    return '' unless body_text
    
    # Strip HTML if present
    text = body_text.gsub(/<[^>]+>/, ' ')
    # Clean up whitespace
    text = text.gsub(/\s+/, ' ').strip
    # Truncate
    text.length > limit ? text[0..limit-1] + '...' : text
  end

  def has_attachments?(payload)
    return false unless payload['parts']
    
    payload['parts'].any? do |part|
      part['filename'].present? || 
      part['mimeType']&.start_with?('application/') ||
      part['mimeType']&.start_with?('image/')
    end
  end

  def parse_gmail_date(date_string)
    return Time.current unless date_string
    Time.zone.parse(date_string)
  rescue
    Time.current
  end

  def sync_history_changes(since_history_id)
    # Implementation for syncing incremental changes
    # This would use the Gmail History API
    Rails.logger.info "Syncing history changes since #{since_history_id}"
  end

  def fetch_and_store_emails
    emails_data = fetch_recent_emails
    
    emails_data.each do |email_data|
      next if email_already_exists?(email_data[:gmail_message_id])
      
      email = create_email_record(email_data)
      
      # Queue for AI analysis
      EmailAnalysisJob.perform_later(email) if email
    end
  end

  def email_already_exists?(gmail_message_id)
    @email_account.emails.exists?(gmail_message_id: gmail_message_id)
  end

  def create_email_record(email_data)
    @email_account.emails.create!(
      email_data.merge(
        organization: @email_account.organization,
        priority_level: 'normal' # Will be updated by AI analysis
      )
    )
  rescue => e
    Rails.logger.error "Failed to create email record: #{e.message}"
    nil
  end
end
